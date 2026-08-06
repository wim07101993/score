package bootstrap

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"score/internal/api"
	"score/internal/auth"
	"score/internal/logging"
	"score/internal/oidc"
	"score/internal/server"
	"score/internal/storage"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	"github.com/jackc/pgx/v5/pgxpool"
)

type DependencyContainer struct {
	OidcClientConfig Provider[oidc.ClientConfig]
	DatabaseConfig   Provider[storage.DatabaseConfig]
	Logger           Provider[*slog.Logger]

	ApiServer           Provider[*api.Server]
	ApiServerOpts       Provider[[]api.ServerOption]
	ServerHandler       Provider[*server.Handler]
	AuthSecurityHandler Provider[*auth.SecurityHandler]
	OidcClient          Provider[*oidc.Client]
	PgxPool             Provider[*pgxpool.Pool]
	PgxConn             Provider[*pgxpool.Conn]
	Migrate             Provider[*DependencyWithCleanup[*migrate.Migrate]]

	HttpHandler        Provider[http.Handler]
	ApiSecurityHandler Provider[api.SecurityHandler]
	ApiHandler         Provider[api.Handler]
	AuthOidcClient     Provider[auth.OidcClient]
}

func DefaultDependencyContainer(
	oidcClientConfig Provider[oidc.ClientConfig],
	databaseConfig Provider[storage.DatabaseConfig],
) *DependencyContainer {
	dc := &DependencyContainer{}

	dc.OidcClientConfig = oidcClientConfig
	dc.DatabaseConfig = databaseConfig

	dc.ApiServer = NewLazySingleton(dc.NewApiServer)
	dc.ApiServerOpts = NewLazySingleton(dc.NewApiServerOpts)
	dc.ServerHandler = NewLazySingleton(dc.NewServerHandler)
	dc.AuthSecurityHandler = NewLazySingleton(dc.NewAuthSecurityHandler)
	dc.OidcClient = NewLazySingleton(dc.NewOidcClient)
	dc.PgxPool = NewLazySingleton(dc.NewPgPool)
	dc.PgxConn = NewFactory(dc.NewPgConn)
	dc.Logger = NewFactory(dc.NewLogger)
	dc.Migrate = NewFactory(dc.NewMigrate)

	dc.HttpHandler = NewLazySingleton(dc.NewHttpHandler)
	dc.ApiSecurityHandler = NewFactory(func(ctx context.Context) (api.SecurityHandler, error) {
		return dc.AuthSecurityHandler.Provide(ctx)
	})
	dc.ApiHandler = NewFactory(func(ctx context.Context) (api.Handler, error) {
		return dc.ServerHandler.Provide(ctx)
	})
	dc.AuthOidcClient = NewFactory(func(ctx context.Context) (auth.OidcClient, error) {
		return dc.OidcClient.Provide(ctx)
	})

	return dc
}

func (di *DependencyContainer) NewHttpHandler(ctx context.Context) (_ http.Handler, err error) {
	var apiServer *api.Server

	if apiServer, err = di.ApiServer.Provide(ctx); err != nil {
		return nil, err
	}

	return server.Cors(logging.Wrap(apiServer)), nil
}

func (di *DependencyContainer) NewApiServer(ctx context.Context) (_ *api.Server, err error) {
	var router api.Handler
	var sec api.SecurityHandler
	var opts []api.ServerOption

	if router, err = di.ApiHandler.Provide(ctx); err != nil {
		return nil, err
	}
	if sec, err = di.ApiSecurityHandler.Provide(ctx); err != nil {
		return nil, err
	}
	if opts, err = di.ApiServerOpts.Provide(ctx); err != nil {
		return nil, err
	}

	return api.NewServer(router, sec, opts...)
}

func (di *DependencyContainer) NewServerHandler(ctx context.Context) (_ *server.Handler, err error) {
	return server.New(di.PgxConn), nil
}

func (di *DependencyContainer) NewApiServerOpts(ctx context.Context) (_ []api.ServerOption, err error) {
	return []api.ServerOption{
		api.WithMiddleware(
			logging.AddOperationIdToContext(),
			server.SetAcceptHeaderToContext),
		api.WithErrorHandler(server.ErrorHandler),
		api.WithNotFound(server.NotFound),
		api.WithMethodNotAllowed(server.MethodNotAllowed),
	}, nil
}

func (di *DependencyContainer) NewAuthSecurityHandler(ctx context.Context) (_ *auth.SecurityHandler, err error) {
	var oidcClient auth.OidcClient

	if oidcClient, err = di.AuthOidcClient.Provide(ctx); err != nil {
		return nil, err
	}

	return auth.NewSecurityHandler(oidcClient), nil
}

func (di *DependencyContainer) NewOidcClient(ctx context.Context) (_ *oidc.Client, err error) {
	var config oidc.ClientConfig

	if config, err = di.OidcClientConfig.Provide(ctx); err != nil {
		return nil, err
	}

	return oidc.NewClient(config), nil
}

func (di *DependencyContainer) NewPgPool(ctx context.Context) (_ *pgxpool.Pool, err error) {
	var config storage.DatabaseConfig

	if config, err = di.DatabaseConfig.Provide(ctx); err != nil {
		return nil, err
	}

	return pgxpool.New(ctx, config.ConnectionString)
}

func (di *DependencyContainer) NewPgConn(ctx context.Context) (_ *pgxpool.Conn, err error) {
	var pool *pgxpool.Pool

	if pool, err = di.PgxPool.Provide(ctx); err != nil {
		return nil, err
	}

	return pool.Acquire(ctx)
}

func (di *DependencyContainer) NewLogger(ctx context.Context) (_ *slog.Logger, err error) {
	return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})), nil
}

func (di *DependencyContainer) NewMigrate(ctx context.Context) (_ *DependencyWithCleanup[*migrate.Migrate], err error) {
	config, err := di.DatabaseConfig.Provide(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get database config: %w", err)
	}

	db, err := sql.Open("postgres", config.ConnectionString)
	if err != nil {
		return nil, err
	}

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to initiate postgres driver: %w", errors.Join(err, db.Close()))
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://db/migrations",
		"postgres",
		driver,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create migration runner: %w", errors.Join(err, driver.Close()))
	}
	return &DependencyWithCleanup[*migrate.Migrate]{
		Dependency: m,
		Cleanup: func() error {
			src, db := m.Close()
			return errors.Join(src, db)
		},
	}, nil
}

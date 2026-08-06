package bootstrap

import (
	"context"
	"net/http"
	"score/internal/api"
	"score/internal/auth"
	"score/internal/logging"
	"score/internal/oidc"
	"score/internal/server"
	"score/internal/storage"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Bootstrapper struct {
	OidcClientConfig Provider[oidc.ClientConfig]
	DatabaseConfig   Provider[storage.DatabaseConfig]

	ApiServer           Provider[*api.Server]
	ApiServerOpts       Provider[[]api.ServerOption]
	ServerHandler       Provider[*server.Handler]
	AuthSecurityHandler Provider[*auth.SecurityHandler]
	OidcClient          Provider[*oidc.Client]
	PgxPool             Provider[*pgxpool.Pool]
	PgxConn             Provider[*pgxpool.Conn]

	HttpHandler        Provider[http.Handler]
	ApiSecurityHandler Provider[api.SecurityHandler]
	ApiHandler         Provider[api.Handler]
	AuthOidcClient     Provider[auth.OidcClient]
}

func Default(
	oidcClientConfig Provider[oidc.ClientConfig],
	databaseConfig Provider[storage.DatabaseConfig],
) *Bootstrapper {
	b := &Bootstrapper{}

	b.OidcClientConfig = oidcClientConfig
	b.DatabaseConfig = databaseConfig

	b.ApiServer = NewLazySingleton[*api.Server](b.NewApiServer)
	b.ApiServerOpts = NewLazySingleton[[]api.ServerOption](b.NewApiServerOpts)
	b.ServerHandler = NewLazySingleton[*server.Handler](b.NewServerHandler)
	b.AuthSecurityHandler = NewLazySingleton[*auth.SecurityHandler](b.NewAuthSecurityHandler)
	b.OidcClient = NewLazySingleton[*oidc.Client](b.NewOidcClient)
	b.PgxPool = NewLazySingleton[*pgxpool.Pool](b.NewPgPool)
	b.PgxConn = NewFactory[*pgxpool.Conn](b.NewPgConn)

	b.HttpHandler = NewFactory[http.Handler](func(ctx context.Context) (http.Handler, error) {
		return b.ApiServer.Provide(ctx)
	})
	b.ApiSecurityHandler = NewFactory[api.SecurityHandler](func(ctx context.Context) (api.SecurityHandler, error) {
		return b.AuthSecurityHandler.Provide(ctx)
	})
	b.ApiHandler = NewFactory[api.Handler](func(ctx context.Context) (api.Handler, error) {
		return b.ServerHandler.Provide(ctx)
	})
	b.AuthOidcClient = NewFactory[auth.OidcClient](func(ctx context.Context) (auth.OidcClient, error) {
		return b.OidcClient.Provide(ctx)
	})

	return b
}

func (b *Bootstrapper) NewApiServer(ctx context.Context) (_ *api.Server, err error) {
	var router api.Handler
	var sec api.SecurityHandler
	var opts []api.ServerOption

	if router, err = b.ApiHandler.Provide(ctx); err != nil {
		return nil, err
	}
	if sec, err = b.ApiSecurityHandler.Provide(ctx); err != nil {
		return nil, err
	}
	if opts, err = b.ApiServerOpts.Provide(ctx); err != nil {
		return nil, err
	}

	return api.NewServer(router, sec, opts...)
}

func (b *Bootstrapper) NewServerHandler(ctx context.Context) (_ *server.Handler, err error) {
	return server.New(b.PgxConn), nil
}

func (b *Bootstrapper) NewApiServerOpts(ctx context.Context) (_ []api.ServerOption, err error) {
	return []api.ServerOption{
		api.WithMiddleware(logging.AddOperationIdToContext()),
		api.WithErrorHandler(server.ErrorHandler),
	}, nil
}

func (b *Bootstrapper) NewAuthSecurityHandler(ctx context.Context) (_ *auth.SecurityHandler, err error) {
	var oidcClient auth.OidcClient

	if oidcClient, err = b.AuthOidcClient.Provide(ctx); err != nil {
		return nil, err
	}

	return auth.NewSecurityHandler(oidcClient), nil
}

func (b *Bootstrapper) NewOidcClient(ctx context.Context) (_ *oidc.Client, err error) {
	var config oidc.ClientConfig

	if config, err = b.OidcClientConfig.Provide(ctx); err != nil {
		return nil, err
	}

	return oidc.NewClient(config), nil
}

func (b *Bootstrapper) NewPgPool(ctx context.Context) (_ *pgxpool.Pool, err error) {
	var config storage.DatabaseConfig

	if config, err = b.DatabaseConfig.Provide(ctx); err != nil {
		return nil, err
	}

	return pgxpool.New(ctx, config.ConnectionString)
}

func (b *Bootstrapper) NewPgConn(ctx context.Context) (_ *pgxpool.Conn, err error) {
	var pool *pgxpool.Pool

	if pool, err = b.PgxPool.Provide(ctx); err != nil {
		return nil, err
	}

	return pool.Acquire(ctx)
}

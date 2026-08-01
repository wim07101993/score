package helpers

import (
	"context"
	"database/sql"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/golang-migrate/migrate/v4"
	migratepostgres "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file" // file:// migration source
	"github.com/jackc/pgx/v5/pgxpool"
)

// DatabaseUrlEnvVar points the integration tests at an existing Postgres. When
// it is empty the tests start a throwaway container instead.
const DatabaseUrlEnvVar = "SCORE_TEST_DATABASE_URL"

// MigrationsSource is the migration directory, relative to the package that
// runs the tests.
const MigrationsSource = "file://../../db/migrations"

// PostgresUrl returns a connection string to a Postgres the tests may write to.
// If $SCORE_TEST_DATABASE_URL is set it connects to that database (no docker
// required); otherwise it starts a postgres:16-alpine container. The returned
// stop function is always non-nil and safe to defer.
func PostgresUrl(ctx context.Context) (databaseUrl string, stop func(), err error) {
	if databaseUrl := os.Getenv(DatabaseUrlEnvVar); databaseUrl != "" {
		return databaseUrl, func() {}, nil
	}

	if _, err := exec.LookPath("docker"); err != nil {
		return "", func() {}, fmt.Errorf(
			"no database to test against: set $%s or install docker", DatabaseUrlEnvVar)
	}

	return startPostgresContainer(ctx)
}

func startPostgresContainer(ctx context.Context) (databaseUrl string, stop func(), err error) {
	run := exec.CommandContext(ctx, "docker", "run", "--detach", "--rm",
		"--env", "POSTGRES_USER=postgres",
		"--env", "POSTGRES_PASSWORD=postgres",
		"--env", "POSTGRES_DB=score",
		"--publish", "127.0.0.1::5432",
		"postgres:16-alpine")

	// Only stdout carries the container id; pulling the image logs to stderr.
	var stdout, stderr strings.Builder
	run.Stdout = &stdout
	run.Stderr = &stderr

	if err := run.Run(); err != nil {
		return "", func() {}, fmt.Errorf("failed to start a postgres container: %w: %s", err, stderr.String())
	}

	container := strings.TrimSpace(stdout.String())
	stop = func() { _ = exec.Command("docker", "rm", "--force", container).Run() }

	hostPort, err := publishedPort(ctx, container, "5432/tcp")
	if err != nil {
		stop()
		return "", func() {}, err
	}

	databaseUrl = fmt.Sprintf("postgres://postgres:postgres@%s/score?sslmode=disable", hostPort)
	if err := waitForPostgres(ctx, databaseUrl); err != nil {
		stop()
		return "", func() {}, err
	}
	return databaseUrl, stop, nil
}

// publishedPort resolves the host address docker bound a container port to. The
// mapping is not always available the instant `docker run` returns.
func publishedPort(ctx context.Context, container string, containerPort string) (string, error) {
	deadline := time.Now().Add(30 * time.Second)
	for {
		out, err := exec.CommandContext(ctx, "docker", "port", container, containerPort).Output()
		if err == nil {
			if line := strings.TrimSpace(strings.Split(string(out), "\n")[0]); line != "" {
				return line, nil
			}
		}
		if time.Now().After(deadline) {
			return "", fmt.Errorf("container %s never published %s", container, containerPort)
		}
		time.Sleep(200 * time.Millisecond)
	}
}

func waitForPostgres(ctx context.Context, databaseUrl string) error {
	deadline := time.Now().Add(60 * time.Second)
	for {
		attempt, cancel := context.WithTimeout(ctx, 2*time.Second)
		pool, err := pgxpool.New(attempt, databaseUrl)
		if err == nil {
			err = pool.Ping(attempt)
			pool.Close()
		}
		cancel()

		if err == nil {
			return nil
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("postgres never became ready: %w", err)
		}
		time.Sleep(500 * time.Millisecond)
	}
}

// Migrator builds a migration runner for the given database, mirroring the way
// the application migrates itself on start-up. Close the returned *sql.DB when
// done.
func Migrator(databaseUrl string) (*migrate.Migrate, *sql.DB, error) {
	db, err := sql.Open("postgres", databaseUrl)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to open the database for migrations: %w", err)
	}

	driver, err := migratepostgres.WithInstance(db, &migratepostgres.Config{})
	if err != nil {
		_ = db.Close()
		return nil, nil, fmt.Errorf("failed to create the migration driver: %w", err)
	}

	migrator, err := migrate.NewWithDatabaseInstance(MigrationsSource, "postgres", driver)
	if err != nil {
		_ = db.Close()
		return nil, nil, fmt.Errorf("failed to create the migration runner: %w", err)
	}
	return migrator, db, nil
}

// MigrateUp brings the given database up to the latest migration.
func MigrateUp(databaseUrl string) error {
	migrator, db, err := Migrator(databaseUrl)
	if err != nil {
		return err
	}
	defer func() { _ = db.Close() }()

	if err := migrator.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to migrate up: %w", err)
	}
	return nil
}

// WithDatabaseName points a connection string at another database on the same
// server, so migrations can be exercised without touching the one the API uses.
func WithDatabaseName(databaseUrl string, name string) (string, error) {
	parsed, err := url.Parse(databaseUrl)
	if err != nil {
		return "", fmt.Errorf("failed to parse the database url: %w", err)
	}
	parsed.Path = "/" + name
	return parsed.String(), nil
}

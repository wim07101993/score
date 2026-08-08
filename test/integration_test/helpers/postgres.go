package helpers

import (
	"fmt"
	"io"
	"net"
	"os"

	embeddedpostgres "github.com/fergusstrange/embedded-postgres"
)

const MigrationsSource = "file://../../db/migrations"

func StartEmbeddedPostgres() (databaseUrl string, stop func(), err error) {
	port, err := freePort()
	if err != nil {
		return "", func() {}, err
	}

	runtimePath, err := os.MkdirTemp("", fmt.Sprintf("score-test-postgres-%d-", port))
	if err != nil {
		return "", func() {}, fmt.Errorf("failed to make a directory for the test database: %w", err)
	}

	postgres := embeddedpostgres.NewDatabase(embeddedpostgres.DefaultConfig().
		Version(embeddedpostgres.V18).
		Username("postgres").
		Password("postgres").
		Database("score").
		Port(uint32(port)).
		RuntimePath(runtimePath).
		Logger(io.Discard))

	if err := postgres.Start(); err != nil {
		_ = os.RemoveAll(runtimePath)
		return "", func() {}, fmt.Errorf("failed to start a test database: %w", err)
	}

	stop = func() {
		_ = postgres.Stop()
		_ = os.RemoveAll(runtimePath)
	}

	return fmt.Sprintf("postgres://postgres:postgres@localhost:%d/score?sslmode=disable", port), stop, nil
}

// freePort is a port nothing is listening on. Between finding one and the
// database binding it, nothing else is asked to leave it alone — the window is
// small enough that the alternative is not worth its complexity.
func freePort() (int, error) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 0, fmt.Errorf("failed to find a free port for the test database: %w", err)
	}
	defer func() { _ = listener.Close() }()

	return listener.Addr().(*net.TCPAddr).Port, nil
}

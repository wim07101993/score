# Score

Application to manage sheet-music.

## Authentication

Authentication can be done using any OIDC provider. We use Zitadel in the 
docker-compose file but any OIDC server. Roles are checked using getting the 
user-info from the idp. 

## Development

### Requirements

- GoLang version see go.mod file
    - SDK to develop go applications
  - https://go.dev/dl/
- Docker
  - Tool for running software containers
  - `$ go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest`

### Running

```bash
$ source backend/scripts/set_env_vars.sh
$ go run backend/cmd/server/*
```

### Testing

Unit tests need nothing but a Go toolchain:

```bash
$ go test ./...
```

The integration tests drive the real API over HTTP against a real database, and
are behind a build tag:

```bash
$ go test -tags integration ./test/...
```

They start a throwaway `postgres:16-alpine` container, so docker has to be
running. To use a database of your own instead:

```bash
$ SCORE_TEST_DATABASE_URL=postgres://user:password@localhost:7432/score?sslmode=disable \
    go test -tags integration ./test/...
```

The frontend tests run on node without a build step or any dependency:

```bash
$ cd frontend && node --test
```

### Database

The database is an SQLite file.

#### Add migrations

```bash
$ backend/scripts/create_migration.sh $NAME_OF_YOUR_MIGRATION
```

#### Run migrations

```bash
$ backend/scripts/run_migrations.sh
```

## Deployment

### Frontend

Ensure [config.json](frontend/src/config.json) is modified to contain the correct
client-id and uri's.

Client must be configured to use an Authorization code grant with PKCE with 
refresh tokens enabled. The redirect uri of the web-application is the root.
(see example configs).

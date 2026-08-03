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

The dependencies (a PostgreSQL server on port 7432 with a `score` database on
it, and a Zitadel instance on port 7003) come from the docker-compose file:

```bash
$ docker compose -f docker-compose-dev.yml up -d
```

The server is configured from environment variables, from a JSON file, or from
both — the file wins over the environment:

```bash
$ export DB_CONNECTION_STRING=postgres://postgres:postgres@localhost:7432/score?sslmode=disable
$ export TOKEN_INTROSPECTION_URL=http://localhost:7003/oauth/v2/introspect
$ export TOKEN_INTROSPECTION_CLIENT_ID=...
$ export TOKEN_INTROSPECTION_CLIENT_SECRET=...
$ export USER_INFO_URL=http://localhost:7003/oidc/v1/userinfo
$ export ROLES_KEY=urn:zitadel:iam:org:project:roles
$ go run .
```

```bash
$ go run . -config ./config.json
```

`HTTP_SERVER_PORT` (`httpServerPort` in the file) defaults to 7001. Every other
setting is required and the server refuses to start without it. The server runs
the migrations itself on start-up, so `db/migrations` has to be reachable from
the working directory.

The frontend is served by a static file server of its own:

```bash
$ cd frontend && go run frontend.go
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

The database is PostgreSQL. The schema lives in [db/migrations](db/migrations)
and is applied by the server itself on start-up; the scripts below are for
working on the migrations by hand.

#### Add migrations

```bash
$ scripts/create_migration.sh $NAME_OF_YOUR_MIGRATION
```

#### Run migrations

```bash
$ scripts/run_migrations.sh
```

## Deployment

### Frontend

Ensure [config.json](frontend/src/config.json) is modified to contain the correct
client-id and uri's.

Client must be configured to use an Authorization code grant with PKCE with 
refresh tokens enabled. The redirect uri of the web-application is the root.
(see example configs).

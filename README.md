# Score

Application to manage sheet-music.

## The API

The API is described in [api/openapi-spec.yaml](api/openapi-spec.yaml), and the
server that serves it is generated from that document by
[ogen](https://github.com/ogen-go/ogen) into [internal/api](internal/api). The
document is the source of truth: which paths there are, which methods they
answer, which parameters they read, which roles they ask for and what comes
back are all decided there, and the code that routes, reads and validates a
request follows from it.

It is one document spread over many files, a slice per endpoint:

```
api/
├── openapi-spec.yaml            the outline: which paths there are
├── endpoints/
│   ├── healthz/
│   │   ├── methods.yaml         what GET /healthz answers to
│   │   └── get_healthz_response.yaml
│   └── scores/
│       ├── methods.yaml         what GET /scores answers to
│       ├── get_scores_response.yaml
│       └── by_id/
│           ├── methods.yaml     what GET and PUT /scores/{scoreId} answer to
│           ├── get_score_response.yaml
│           ├── put_score_request.yaml
│           └── musicxml_document.yaml
├── parameters/                  what the endpoints read out of a request
├── responses/                   what a failure comes back as, a file per status
├── schemas/                     what more than one endpoint is written in
└── security/
    └── oauth2.yaml              how a caller proves who they are
```

Everything an endpoint alone uses lives in its directory; only what more than
one of them uses sits above them, a directory per kind. Adding an endpoint is
adding a directory and a line in the outline.

A request that could not be served is answered with
[RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) problem details, whichever
endpoint it was aimed at and whether it was a handler or the generated server
that turned it down. On top of the five members the RFC names, every failure
carries an `errorCode`: the status code says how a request failed in the terms
http has, and that says which failure it was in the terms this API has. It is
the one an application should branch on — the set it comes from is in
[api/schemas/problem_details.yaml](api/schemas/problem_details.yaml), and it
only ever grows.

What is left to write by hand is what the operations do
([internal/score](internal/score)) and whether a token may perform them
([internal/auth](internal/auth)).

After a change to the document, generate the server again:

```bash
$ go generate ./...
```

The generator is a [tool dependency](https://go.dev/doc/modules/managing-source)
of the module, so nothing has to be installed for that. What it generates is
checked in, and CI fails when it does not match the document. Its settings —
which parts of ogen are used at all — are in [ogen.yml](ogen.yml).

The generator is happy with plenty a reader of the API would not be, so the
document is also linted as a document — every `$ref` lands, every operation says
who may call it and what it answers:

```bash
$ npx --yes @redocly/cli@2.44.1 lint
```

CI runs exactly that. Which rules it holds the document to, and why, is in
[redocly.yaml](redocly.yaml).

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

They need nothing installed either: they run a real PostgreSQL 16 of their own,
started as a child process on a free port and thrown away afterwards, so a
database you are running yourself is left alone. The first run downloads the
server binaries and caches them under `~/.embedded-postgres-go`; every run after
that starts from what is already there.

To use a database of your own instead — no download, and the tests write to it:

```bash
$ SCORE_TEST_DATABASE_URL=postgres://user:password@localhost:7432/score?sslmode=disable \
    go test -tags integration ./test/...
```

The API's own log is silenced during a test run. To see it:

```bash
$ SCORE_TEST_LOG=1 go test -tags integration ./test/...
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

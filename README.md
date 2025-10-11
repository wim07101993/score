# Score

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

Ensure [config.js](frontend/src/config.js) is modified to contain the correct
client-id and uri's.

Client must be configured to use an Authorization code grant with PKCE with 
refresh tokens enabled. The redirect uri of the web-application is the root.
(see example configs).

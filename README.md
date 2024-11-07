# Score

## Development

### Requirements

- GoLang version 1.21 
    - SDK to develop go applications
  - https://go.dev/dl/
- Migrate
  - Migration tool for migrating sql databases
  - `$ go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest`
- Protoc
  - Tool for generating code from proto files
  - https://grpc.io/docs/protoc-installation/

### Running

```bash
$ source backend/scripts/set_env_vars.sh
$ go run backend/cmd/server/*
```

### Database

The database is an SQLite file.

#### Add migrations

```bash
$ migrate create -ext .sql -dir backend/db/migrations -seq $NAME_OF_YOUR_MIGRATION
```

#### Run migrations

```bash
$ backend/scripts/run_migrations.sh
```

### gRPC

#### Generate servers

```bash
$ backend/scripts/run_migrations.sh
```
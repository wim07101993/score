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
│   ├── scores/
│   │   ├── methods.yaml         what GET /scores answers to
│   │   ├── get_scores_response.yaml
│   │   └── by_id/
│   │       ├── methods.yaml     what GET and PUT /scores/{scoreId} answer to
│   │       ├── get_score_response.yaml
│   │       ├── put_score_request.yaml
│   │       └── musicxml_document.yaml
│   └── sets/
│       ├── methods.yaml         what GET /sets answers to
│       ├── set.yaml             what more than one of these is written in
│       ├── set_entry.yaml
│       ├── entry_view.yaml
│       └── by_id/               a resource under a resource is a directory
│           ├── methods.yaml         under a directory: the path is the path
│           └── entries/
│               └── by_id/
│                   ├── methods.yaml
│                   └── view/
│                       └── methods.yaml
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

## The frontend

The frontend is plain ES modules served as files — no build step, no
dependencies, one page per thing there is to look at:

```
frontend/src/
├── index.html                   the scores there are
├── scores/detail.html           one score, drawn and played from
├── sets/index.html              the sets there are
├── sets/detail.html             one set, written
├── domains/                     what the app knows, a directory per subject
│   ├── auth/                    proving who the user is
│   ├── scores/                  the scores and the way one is looked at
│   └── sets/                    the playlists a gig is played from
├── components/                  the custom elements a list is drawn with
└── service-worker.js            what is served when there is no network
```

A domain is three files that stack: an `api.js` that speaks to the server, a
`database.js` that keeps what came back, and a `repository.js` that is the only
thing a page talks to. A page reads what is stored and asks for a sync; it never
waits on the network to draw.

### Finding out why the app shows nothing

Every page decides what to show from the roles the provider sent: a page that
shows nothing is a page that was told nothing. What it was told is on
[profile.html](frontend/src/profile.html), which is linked from the scores page
and is never hidden, whatever roles the user turns out to have — a user who is
shown nothing at all is exactly the user who needs to see why.

It shows the user-info answer as it came back, which claim the roles were looked
for under and which claims actually arrived, whether the answer came from the
provider just now or from the copy this device kept, what the app is talking to
and whether it can be reached, what is stored on the device, and which cached
versions of the app are on it. It also carries the two ways out: forgetting the
tokens to sign in again, and throwing away the cached app to fetch the newest
one.

That last one is worth knowing about. A page is served from the cache before it
is served from the network, which is what makes the app work with no network at
all — and also what keeps a version that has been replaced on screen. The worker
takes over as soon as it is installed and deletes the caches of every earlier
version when it does, so an update lands on the next load; before it did that, a
new version was cached and left untouched while the previous one went on being
served for as long as a tab of the app stayed open.

### Sets are written offline

A set is a playlist for a gig, and a gig is exactly where there is no network,
so a set that could only be written online is a set that could not be written
when it was needed. Every edit is therefore stored on the device first and
marked as owed to the server, and pushed the moment the server can be reached —
at the end of the edit when that is right away, and at the next sync otherwise.
Every page that syncs pushes what is queued, so an edit made at a gig goes out
as soon as the app is opened anywhere with a network.

Two rules keep that from losing anything:

- **What was written here wins until it has been pushed.** A set with an edit
  still owed is never overwritten by what a sync brings in: it was written after
  the last thing the server said, so it is the newer of the two by definition.
- **A refusal is either worth retrying or it is not**, and
  `SetsApiError.isWorthRetrying` is where that is decided. A network that is
  down, a server that is unwell, a token that ran out — none of them say
  anything about what was written, so the edit stays queued. A set naming a
  score that does not exist is refused just as firmly next time, so the edit is
  given up on, the set is read back the way the server has it, and the player is
  told. An edit dropped quietly is worse than one dropped loudly.

A deleted set is kept as a headstone rather than dropped, the same way the
server keeps it: a sync only asks about what changed since the last one, so a
set that was simply forgotten would be fetched straight back in as something
new.

### A set says what the band plays; a view says what one player looks at

An entry carries the key the band plays a song in, which is the arrangement and
the same for everybody. How far one player reads it from there, and which parts
they have on screen, is theirs: the saxophone player wants their part a sixth up
with the vocals next to it, the pianist wants the piano staff alone in the
written key, and both are looking at the same entry of the same set.

So an entry carries a `view` as well, and that view belongs to whoever asked for
the set. Everyone it is shared with has their own, everyone writes their own
without being the owner — `PUT /sets/{setId}/entries/{entryId}/view` asks no
more of a player than reading the set does — and nobody is told anything about
anybody else's. What ends up on screen is the two transpositions added, held to
the octave either way the player offers.

None of it touches the score. Both halves are applied to what is drawn, so two
sets can play the same score in different keys, and two players can read the
same set in different keys, without any of them changing anything. That is what
`ScoreView` is: a way of looking at a score, which an entry and a view together
describe and the score page opens with.

Which parts are off screen is set while playing rather than while writing the
set: the parts a score has are in its document, and the document is not read
until the score is drawn. So the score page carries a button that writes the way
it is currently being looked at back into the view of the entry it was opened
from — as that player's own reading of it, never as the set's.

### Three resources, not one

A set is what the gig is and who may read it. What is played in it is not part
of that: an entry is a resource of its own, and so is one player's view of an
entry. Each is written by itself, and by a different person for a different
reason.

```
PUT    /sets/{setId}                              the gig      the owner
PUT    /sets/{setId}/entries/{entryId}            a song       the owner
DELETE /sets/{setId}/entries/{entryId}
PUT    /sets/{setId}/entries/{entryId}/view       how I read it  everyone
```

A set is therefore created empty and filled afterwards, a song at a time. What
that buys is that correcting a title is correcting a title: a client that has not
looked at the running order in a while cannot undo it by saying nothing about
it, and a client that added one song sends one song. A read still hands the
whole thing over — `GET /sets/{setId}` returns the set with its entries in
playing order, each carrying the caller's own view — because reading a running
order is reading a running order.

Where a song is played is `position`, counting from zero. The set is closed up
around it: writing an entry at a place the set already has one in puts that one
and everything after it back by one, and an entry already in the set that is
written at another place moves there. What the rest are numbered afterwards is
the server's, and it is always nought upwards with no gaps. A place past the end
is the end rather than a refusal — a client catching up after a gig it spent
offline is saying where a song goes, and the nearest place it can go is a better
answer to that than a rejected write.

Two more things are worth knowing about:

- **An entry keeps its id for as long as it is in the set.** The id is the
  client's to name, which is what lets a player add a song at a gig and say how
  they read it before either has reached the server. An id belonging to another
  set's entry is refused rather than taken over. An entry that leaves the set
  takes every view of it along.
- **A set is last changed at the later of two moments**, and which two depends on
  who is asking: when the set or its running order was written, and when the
  caller last wrote a view of one of its entries. A sync asks for everything that
  changed *for the caller*, and a view they wrote on another device is exactly
  that — while somebody else writing theirs is not, and never turns up in their
  window.

On the client the same three-way split holds, and so does the queue. A set owes
the server three separate things: `pending_change` for what the set is,
`pending_entries` for the songs added, moved or taken out here, and
`pending_views` for how they are read. They go out in that order, because each
is written against the one before it — an entry against a set, a view against an
entry — so whatever did not get through keeps what depends on it queued behind
it. The editor reflects that: the save button writes what the set is, and
everything about the running order lands as it is done.

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

`HTTP_SERVER_PORT` (`httpServerPort` in the file) defaults to 7001, and
`MAX_REQUEST_BODY_BYTES` (`maxRequestBodyBytes`) to 32MiB — the largest score
this server will read, and what keeps one upload from deciding how much memory
it uses. Every other setting is required and the server refuses to start
without it. The server runs the migrations itself on start-up, so
`db/migrations` has to be reachable from the working directory.

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

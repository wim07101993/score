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
│   ├── sets/
│   │   ├── methods.yaml         what GET /sets answers to
│   │   ├── set.yaml             what more than one of these is written in
│   │   ├── set_entry.yaml
│   │   └── by_id/               a resource under a resource is a directory
│   │       ├── methods.yaml         under a directory: the path is the path
│   │       └── entries/
│   │           └── by_id/
│   │               ├── methods.yaml
│   │               └── view/
│   │                   └── methods.yaml
│   └── collections/             the same shape, less the running order
│       ├── methods.yaml
│       ├── collection.yaml
│       ├── collection_entry.yaml
│       └── by_id/
│           ├── methods.yaml
│           └── entries/
│               └── by_id/
│                   ├── methods.yaml
│                   └── view/
│                       └── methods.yaml
├── parameters/                  what the endpoints read out of a request
├── responses/                   what a failure comes back as, a file per status
├── schemas/                     what more than one endpoint is written in
│   ├── problem_details.yaml
│   ├── entry_view.yaml          a set and a collection are read the same way
│   └── write_entry_view.yaml
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

The frontend is a Flutter app in [frontend/](frontend), and it is one app: the
same code runs in a browser, on a Linux or Windows desktop and on Android, so
what a player reads off a phone at a gig is the same drawing they read off a
browser at home. How it is built — how a score is drawn, what the lamp on the
page is, and what has to be registered with the provider per platform — is in
[its own README](frontend/README.md).

Two things about it decide how the rest of this document reads:

- **A page reads what is stored and asks for a sync; it never waits on the
  network to draw.** A score is read on a stage and a set is written at a gig,
  and both of those are exactly where there is no network.
- **What this device prefers is the device's and not the account's.** Which way
  round the app is, and how much light the page a score is drawn on throws, are
  kept on the device and never sent to the server: a player reads off a bright
  laptop at home and a dimmed tablet on a stand as the same person, and neither
  should decide the other.

It replaced a frontend of plain ES modules that drew sheet music with
[OpenSheetMusicDisplay](https://opensheetmusicdisplay.org) and therefore only
ever ran in a browser. That one is gone; the git history has it if something it
decided needs looking up.

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
the same for everybody. How far one player reads it from there, which parts they
have on screen, and how big it is drawn, is theirs: the saxophone player wants
their part a sixth up with the vocals next to it, the pianist wants the piano
staff alone in the written key, and the one with the tablet across the room
wants all of it twice the size. All of them are looking at the same entry of the
same set.

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
until the score is drawn. The same goes for how big it is drawn, which is a
pinch on the music itself. So the score page writes the way it is being looked
at back into the view of the entry it was opened from — as that player's own
reading of it, never as the set's.

It writes it as the player changes it, the way everything else about a set is
written as it is changed. There is nothing to press: transposing a song at a
gig and then having to remember to say so is a way of losing it. The writes are
held back a moment, since dragging a transposition across an octave is a
handful of changes and what is worth storing is where they came to rest, and
anything still waiting goes out when the page is left. A score that is still
opening the way the set says it is played writes nothing at all — what is on
screen then is the page catching up, not the player reading.

A pinch is answered by drawing the score again rather than by stretching what is
on screen: the music is laid out to the width it has, so a score that is blown
up is broken over more systems and stays as wide as the screen. Music that had
to be scrolled sideways would be unreadable at a gig. While the fingers are
still down it is stretched, since redrawing every pixel of a pinch would leave
the music trailing behind them, and what is stretched is exactly what letting go
draws.

### Not every song has a score

Half of what a band plays is on paper, in a folder, on a stand. A running order
that could only name what has been uploaded is not the running order, so an
entry may have no score at all: a place in the gig with nothing to open, called
by whatever is written next to it. The way through a set steps to it like any
other song and says what it is when it gets there — stepping over it would have
the player looking at the wrong song when the band starts the next one. When
somebody gets round to uploading it, the same entry is given a score and keeps
its place and everything anybody said about it.

### A set is a gig; a collection is a book

The other way a player groups music is not an order at all. A book the pieces
are printed in, the repertoire of a band you play with, everything you know in
one key — the pieces belong together, but nothing says which comes first, and a
piece is either in it or it is not. Writing that down as a set means inventing a
running order nobody means anything by, and a number nobody means anything by is
a number somebody will end up sorting on.

So a collection is its own resource, mirroring a set. Two things differ, and
they are the only two:

- **There is no position.** A collection comes back by title, which is not an
  order it has — it is the order a list somebody is looking through should be
  in. What a piece is called is in its score rather than in its entry, so the
  server sorts by the title it stored and the pages sort by the title they draw,
  and a piece with no score is filed under what is written next to it, which is
  the only name it has.
- **A score is in a collection at most once.** That is the whole of what makes a
  collection a collection. It is held in the server, in a partial unique index,
  and on the device, so that a player who is offline is told they already have a
  piece at the moment they add it rather than at the next sync. The pieces that
  have no score are outside the rule: they are told apart by what is written
  next to them, and two lines of a book nobody has scanned are two pieces.

  Which is why one of those has to be called something, and a set does not. A
  blank line in a running order is a place in the gig, and where it comes is
  what it means; a collection has nowhere for a piece to come, so an unnamed one
  cannot be found, cannot be sorted, and cannot be told from the next unnamed
  one. The server refuses it, the device refuses to queue it, the Add button is
  off until there is a name, and clearing the box of a piece that has no score
  puts the name back rather than taking it away.

Being told a collection already holds a piece is not a refusal to show somebody.
What they wanted was the piece to be in the book, and it is — so the answer
carries `entryId`, the entry it is already in, and the page scrolls to it and
lights it for a moment instead of putting up a dialog. It is the one refusal
`CollectionsApiError` singles out.

Everything else is the same, because it is the same music read by the same
people: a collection is shared by address, its entries carry the key the group
plays a piece in, every player has their own view of every entry, and all of it
is written on the device first and pushed afterwards. A view is literally the
same schema in both — `api/schemas/entry_view.yaml` — because a piece read a
fourth up off a tablet at arm's length is read that way whether it was opened
out of a gig or out of a book. What a view belongs to is the entry, so a score
that is in a set and in a collection is two entries and two views: the band's
arrangement of it and the book's are two different things to read.

The score page opens either. `perform.html?set=…&entry=…` and
`perform.html?collection=…&entry=…` are the same page, and the way through steps
along whichever list it came out of — the running order for a gig, the titles
for a book.

### Three resources, not one

A set is what the gig is and who may read it. What is played in it is not part
of that: an entry is a resource of its own, and so is one player's view of an
entry. Each is written by itself, and by a different person for a different
reason.

```
PUT    /sets/{setId}                              the gig        the owner
PUT    /sets/{setId}/entries/{entryId}            a song         the owner
DELETE /sets/{setId}/entries/{entryId}
PUT    /sets/{setId}/entries/{entryId}/view       how I read it  everyone
```

A collection is the same three, and the same split for the same reasons:

```
PUT    /collections/{id}                          the book       the owner
PUT    /collections/{id}/entries/{entryId}        a piece        the owner
DELETE /collections/{id}/entries/{entryId}
PUT    /collections/{id}/entries/{entryId}/view   how I read it  everyone
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

**A token that has run out takes away the API and nothing else.** The scores are
on the device and are drawn from the device, so nothing about signing in is
allowed to stop the app from starting: `App.updateAuth` never throws, and every
way of failing to ask — a provider that cannot be reached, one that will not
take the token, one that answers something unreadable — ends where having no
network at all ends, at the copy of the answer this device kept the last time it
could ask. The profile page says which of the two it is looking at.

A token also has to know when it runs out, and carry it. It used to be dropped
by a timer, and a timer dies with the page: a tab closed with time left on a
token and opened an hour later found the token still in the storage, sent it,
and was told 401 — which, before this, was an uncaught error at the top of every
page and an app that did not start. The moment it expires is now stored with it
and read every time it is fetched. A token that is refused anyway is thrown away
and the question asked once more with a fresh one, and once only: a provider
that refuses a token it has just issued will go on refusing, and a loop between
the two is worse than being told.

## Development

### Requirements

- GoLang version see go.mod file
    - SDK to develop go applications
  - https://go.dev/dl/
- Docker
  - Tool for running software containers
  - `$ go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest`
- Flutter, for the frontend
  - CI is pinned to 3.47.1 (see `.github/workflows/flutter-*.yml`); the SDK
    decides what the analyzer complains about and what the engraving code
    renders, so it is worth matching
  - https://docs.flutter.dev/get-started/install

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

The frontend is a Flutter app of its own, and on the web the port is not a
detail — the provider compares a redirect address exactly, and port 3000 is the
one [frontend/assets/config.json](frontend/assets/config.json) registers:

```bash
$ cd frontend
$ flutter run -d chrome --web-port=3000
$ flutter run -d linux
```

A desktop build needs no port lined up by hand; what each platform asks for is
in [frontend/README.md](frontend/README.md).

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

The frontend has tests and an analyzer, and CI holds both to the same bar —
`--fatal-infos`, so an advisory lint is a failure too:

```bash
$ cd frontend
$ flutter analyze --fatal-infos
$ flutter test
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

Ensure [assets/config.json](frontend/assets/config.json) is modified to contain
the correct client-id and uri's. It is read at start-up rather than compiled in,
so the same build can be pointed at a development server and at a real one.

Client must be configured to use an Authorization code grant with PKCE with 
refresh tokens enabled. The redirect uri of the web-application is the root. A
device and a desktop each need one of their own — `nativeRedirectUri` and
`desktopRedirectUri` — because an app cannot be sent back to a web page.

The web build is published as a docker image by
[.github/workflows/release.yaml](.github/workflows/release.yaml),
which packages the build the release already produced behind nginx
([frontend/web.nginx.conf](frontend/web.nginx.conf)); the desktop and Android
builds are attached to the release as files.

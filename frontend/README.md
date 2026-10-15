# The frontend, in Flutter

The frontend of [score](../README.md), written once and run on the web, on a
desktop and on a phone.

It replaced a frontend of plain ES modules, and the one thing that is not a
translation of it is the score itself. That app drew sheet music with
[OpenSheetMusicDisplay](https://opensheetmusicdisplay.org), which is JavaScript
and only runs in a browser. This one draws it in Dart, so what a player sees on a
phone at a gig and what they see in a browser at home is the same drawing, worked
out by the same code.

## Drawing a score

The engraving itself is not in this repository. It comes from the `songbird_*`
packages in [pubspec.yaml](pubspec.yaml): `songbird_score` is what a score is,
`songbird_musicxml` reads and writes the file format, and
`songbird_music_notation` lays a score out and paints it, with the Bravura glyphs
it brings along. What is left here is the little the app adds on top:

```
lib/features/notation/
├── parts.dart           reading a document, and naming the parts it has
├── sheet_palette.dart   the page and the ink, chosen together
├── view/                reading it a different way
│   ├── score_view.dart      which parts are on screen, and how far it is moved
│   └── musicxml_view.dart   the document as the view has it, for a download
└── widgets/
    └── score_sheet.dart the sheet: a document, a view and a palette, handed
                         to the engraver
```

**A view is never written into the document.** Hiding a part or transposing is
asked of the score the sheet has read, on the way to the screen; the file the
app holds stays the one the editor uploaded. The download button takes the same
two steps on a score of its own (`musicXmlForView`) and writes that out, so the
score on screen and the file that comes out agree, and a view that changes
nothing downloads the editor's own file byte for byte. A view is immutable, so
putting a score back the way it was is a matter of keeping the old view around.

### Light and dark

The app follows the machine unless the reader says otherwise in **Settings**,
which is remembered on the device and never sent anywhere: a tablet on a stand
and a laptop at home are set separately while being the same account.

The page a score is drawn on follows the app, and the two colours it is drawn
with are chosen **together** — `SheetPalette` in
[lib/features/notation/sheet_palette.dart](lib/features/notation/sheet_palette.dart) holds both, and
the sheet paints its own paper. Splitting them is not a style question: paper
fixed to white while the ink followed a dark theme is pale grey notes on a white
page, which is how this arrived.

### The page has a lamp on it

**A score is ink on paper however dark the room is.** Every dark page that
inverted it — light marks on a dark ground — was uncomfortable, and no amount of
moving the two tones nearer or further apart fixed it, because the distance
between them was never the problem. A screen is not paper. Paper gives back a
share of the light already in the room; a screen makes its own and pushes it at
the reader, so in the dark, when the eye is wide open, anything bright on it
*blooms* — and on an inverted page the bright thing is the notehead being read.
Dark marks have no light to bloom with.

So dark is the same page with the lamp turned down, and the lamp is the reader's:

| dial | what it is | range |
|---|---|---|
| **Brightness** | what the page gives off, as a share of a white one | 18% – 100% |
| **Warmth** | how far from grey it is, up to paper by candlelight | 0 – 100% |

Both live in **Settings**, kept **per page** — the lamp a reader wants at a lit
desk is not the one they want at a gig, so the light page and the dark page each
remember their own, and switching between them does not undo either.

Two details that make the dials feel like dials:

- **Brightness is a share of light, not of the number a colour is written with.**
  Half way down the scale is a page throwing half the light, which is `#BCBCBC`,
  nowhere near the halfway `#808080`. The scale is worked in luminance and turned
  back into a colour at the end, so dragging it dims evenly instead of doing
  nothing at one end and falling off a cliff at the other.
- **Warmth takes light away rather than adding it.** Red is worth about three
  times as much light as blue, so the nine points of red it adds buy back the
  twenty-six it takes out of blue, and the brightness dial stays where it was
  left. Two dials that moved each other would be two dials nobody could set.

The ink takes a little of the warmth too — a black that stayed blue-black on a
warm page reads as a hole in it — and grace notes are faded less on a dim page
than on a bright one, because fading spends contrast and a dim page has less of
it to spend.

**A staff line has to be the ink, not a smear of it.** A staff line is an
eighth of a staff space, which at a readable zoom is about one pixel — and a
one-pixel line laid across the boundary between two pixels is drawn as two rows
at half cover, and half cover is half ink and half page:

```
         ink   page     what a staff line came out as
bright   #000  #FFF     #808080   — still obviously a line
dimmed   #111  #939     #525356   — half way to the page: smoke
```

On white that is survivable; on a dimmed page it is a staff that dissolves under
notes that stay crisp. It is what the first attempts at a dark page spent
contrast making up for, which is how they ended up as glaring as they were. The
app's own painter used to put every hairline on whole device pixels to avoid it;
the painting is `songbird_music_notation`'s now, and it does not snap lines to
device pixels itself, so a dim page is worth checking by eye after an upgrade
of it. The sample staff on the settings page is drawn on whole rows, so that the
lamp is judged by the ink rather than by the smear.

## The rest of the app

```
lib/
├── main.dart        runs the app in a zone that catches what nothing else did
├── app.dart         starting up, and which page an address leads to
├── get_it.dart      everything the app is made of, registered on GetIt
├── router.dart      the addresses, and what is behind a link to one (AutoRoute)
├── config.dart      where the API is, and how a user proves who they are
├── storage/         the databases on the device (sembast), what a feature's store is
│                    built from, and what every API client shares
├── behaviours/      what more than one behaviour shares
├── notifiers/       what every notifier is: the store, followed
├── features/        what the app knows, a directory per subject
│   ├── auth/            proving who the user is
│   ├── scores/          the scores and the documents behind them
│   ├── sets/            the playlists a gig is played from
│   ├── collections/     the scores kept together under a name
│   ├── sync/            squaring what is on the device with the server
│   ├── notation/        drawing a score (above)
│   ├── observability/   logging, kept in the local store across runs, and the logs page
│   ├── settings/        what this device prefers, which is not the account's
│   ├── files/           how a file leaves the app
│   └── app_update/      noticing that a newer build is out
└── widgets/         the pieces more than one page is made of
```

A subject is built in layers, each in a directory of its own:

- `widgets/` — the pages. A page draws what a **notifier** holds, and does
  what the player asks by calling a **behaviour**. It never talks to the
  store or the API.
- `notifiers/` — what a page is drawn from. A notifier follows the store
  through sembast's snapshot streams, so whatever writes to the store — a
  behaviour, a sync, another tab of the web app — is on screen without
  anybody telling the page.
- `behaviours/` — one class per thing the app does (the
  [behaviour](https://pub.dev/packages/behaviour) package): `SaveSet`,
  `SyncScores`, `SignOut`. A behaviour fetches from the API, decides, and
  writes to the store; it hands back what went wrong rather than throwing,
  and every one of them is logged on its way through. What two behaviours
  share — the sync engine of the sets and collections — is here too.
- `storage/` — what keeps or fetches: the API client, and the feature's own
  store in the databases on the device (`ScoresStore`, `SetsStore`, …). No
  feature reads or writes another's.

`models.dart` is what the subject holds, and `get_it.dart` registers the
rest: notifiers are made the first time they are asked for and handed out
once they hold what the store holds, and behaviours are made fresh each time.
So the way through the app is always the same: a button calls a behaviour,
the behaviour writes to the store, the store tells the notifier, and the
notifier redraws the page. **A page reads what is stored and asks for a sync;
it never waits on the network to draw.** A score is read on a stage and a set
is edited at a gig, and both of those are exactly where there is no network.

The rules a set is written under — what is queued, in what order it goes out,
and what happens when the server refuses — are the ones
[the project README](../README.md#sets-are-written-offline) describes. A set
owes the server three separate things in order: what the set is, the songs
added or moved, and how this player reads them. Each is written against the
one before it, so whatever did not get through keeps what depends on it queued
behind it.

## Things to know

- **Tokens survive a restart.** A device that is closed and opened again at the
  next rehearsal should not ask the player to sign in again.
- **A device needs a redirect address of its own.** An app cannot be sent back
  to a web page, so the `redirectUri` of `mobileClient` (default
  `app.wvl.score://callback`) and `desktopClient` (default
  `http://localhost:7005`) in [assets/config.json](assets/config.json) have to
  be registered with the provider. Zitadel wants a native application for them
  rather than the web one: put its client id in `mobileClient` and
  `desktopClient`. Left out, a platform signs in as `client`.
  [assets/config.prod.json](assets/config.prod.json) must carry both: the
  release workflow refuses to publish without them.
- **The score can be written out as MusicXML, but not yet as a picture.** That
  would be writing what the engraver paints out as SVG, which has not been
  done.

## Running it

```bash
$ flutter run -d chrome --web-port=3000   # CHROME_EXECUTABLE=/usr/bin/chromium if needed
$ flutter run -d linux
$ flutter test
$ flutter test --platform chrome test/features/score_list/score_documents_web_test.dart   # the browser's file system
$ dart run build_runner build             # after changing a page's route: writes lib/router.gr.dart
```

**The port on the web is not a detail.** A provider compares a redirect address
exactly, port and all, and `flutter run -d chrome` on its own picks a free port
at random — so the app is served from an address the provider has never heard
of, and a sign-in started there would send the player somewhere nothing is
listening. `--web-port=3000` is the address registered in
[assets/config.json](assets/config.json). Started anywhere else the app says so
and refuses, rather than leaving on a journey it cannot finish.

A desktop has no such problem: it listens on `desktopRedirectUri`'s port itself,
for as long as the sign-in takes, so there is nothing to line up by hand.

[assets/config.json](assets/config.json) is read at start-up rather than
compiled in, so the same build can be pointed at a development server and at a
real one.

### The web app works without a network

The web app is installable (it has a manifest and a service worker) and, once
it has been opened once with a network, opens and works without one — the same
as the apps on a device. That takes a build made for it:

```bash
$ flutter build web --release --no-web-resources-cdn
$ dart run tool/precache.dart
```

- `--no-web-resources-cdn` serves CanvasKit with the app rather than from
  Google's CDN, and the text font is shipped in
  [assets/fonts/roboto](assets/fonts/roboto) rather than downloaded — either one
  fetched from somewhere else is an app that does not draw offline.
- [tool/precache.dart](tool/precache.dart) writes into the service worker the
  build left behind which files it keeps, with a hash of each. A release that
  changed anything is a service worker that changed, which is how it reaches a
  browser that already has the app; the files that did not change are not
  fetched again.
- [web/service-worker.js](web/service-worker.js) keeps the app and answers
  every address of it out of what is kept. It sits at the address the app
  before this one registered its worker at, so a browser still running that one
  is handed this one at its next update check and throws the old cache away.
- [web/flutter_bootstrap.js](web/flutter_bootstrap.js) registers it — only for
  a build, not for `flutter run` — instead of Flutter's own worker, which only
  unregisters itself. It also asks the browser to keep the app's storage
  persistently, so that downloaded scores and unsent edits are not what a full
  phone throws away first.

The CI's web build (`.github/workflows/flutter-build.yml`) does both steps.

### What the desktop builds need

**Linux needs libsecret, and a keyring to keep the sign-in in.** The tokens
are kept in the platform's secret store (`flutter_secure_storage`, through
`package:oidc`'s default store — see
[lib/features/auth/storage/oidc_user_manager.dart](lib/features/auth/storage/oidc_user_manager.dart)),
which on Linux is the Secret Service: GNOME Keyring or KWallet, running in the
user's session. To build, install `libsecret-1-dev` on top of Flutter's own
Linux prerequisites; to run the released bundle, `libsecret-1-0` and a keyring.
The sign-in itself sends the browser to the provider and catches the answer on
a local port, so no webview is linked.

**Windows needs nothing extra.** The Visual C++ runtime the app is built
against is copied next to `score.exe` by the build
([windows/CMakeLists.txt](windows/CMakeLists.txt)), so the zip runs on a
Windows that has never had the redistributable installed.

On both, **one copy of the app runs at a time**. Two would share one store
file and overwrite each other's unsent edits, so starting it again brings the
window that is already open to the front instead.

### Android is pinned to AGP 8

What is pinned is the Android Gradle Plugin —
[android/settings.gradle.kts](android/settings.gradle.kts) — and not Flutter,
which stays wherever the machine has it.

The pin was for `flutter_web_auth_2`, which brought its own Kotlin compiler
under AGP 9 where `file_picker` expected the built-in one, and the two could not
both build. `flutter_web_auth_2` is gone — signing in is `package:oidc`'s now,
and on Android its `oidc_android` receives the answer on an activity of its own
(the `oidcRedirectScheme` placeholder in
[android/app/build.gradle.kts](android/app/build.gradle.kts)). Whether
`file_picker` 13 and `oidc_android` build under AGP 9 has not been checked yet;
until it has, the pin stays.

**Undoing the pin:**

1. `com.android.application` back to 9.x and Gradle back to 9.x
2. `android.builtInKotlin=true` in [android/gradle.properties](android/gradle.properties)
3. drop `org.jetbrains.kotlin.android` from
   [android/app/build.gradle.kts](android/app/build.gradle.kts) — AGP compiles
   `MainActivity.kt` itself from then on

and build. A failure naming `GeneratedPluginRegistrant` and a plugin class it
cannot find is a plugin still bringing its own compiler, which is what the pin
is for.

Nothing in `lib/` is involved either way.

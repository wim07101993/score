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
putting a score back the way it was is a matter of keeping the old view around —
which is not true of the app this replaces: OSMD rewrites the sheet it holds in
memory, and asking it for a transposition of zero again does not put the keys
back.

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
├── main.dart        starting up, and which page an address leads to
├── routes.dart      the addresses, the ones the app it replaces used
├── app.dart         everything wired together once
├── config.dart      where the API is, and how a user proves who they are
├── features/        what the app knows, a directory per subject
│   ├── auth/            proving who the user is
│   ├── scores/          the scores and the documents behind them
│   ├── sets/            the playlists a gig is played from
│   ├── collections/     the scores kept together under a name
│   ├── notation/        drawing a score (above)
│   ├── settings/        what this device prefers, which is not the account's
│   ├── sembast/         where things are kept on the device
│   ├── files/           how a file leaves the app
│   └── app_update/      noticing that a newer build is out
└── widgets/         the pieces more than one page is made of
```

A subject is an `api.dart` that speaks to the server, `models.dart` for what it
holds, and a `repository.dart` that is the only thing a page talks to. **A page
reads what is stored and asks for a sync; it never waits on the network to
draw.** A score is read on a stage and a set is edited at a gig, and both of
those are exactly where there is no network.

The rules a set is written under — what is queued, in what order it goes out,
and what happens when the server refuses — are the ones
[the project README](../README.md#sets-are-written-offline) describes, and they
were ported from the app this replaced rather than reinvented. A set owes the
server three separate things in
order: what the set is, the songs added or moved, and how this player reads
them. Each is written against the one before it, so whatever did not get through
keeps what depends on it queued behind it.

## Where it differs from the app it replaces

- **Tokens survive a restart.** The old app kept them in `sessionStorage`, which
  lasts as long as a tab. A device that is closed and opened again at the next
  rehearsal should not ask the player to sign in again, and a refresh token that
  lives no longer than a tab never gets used.
- **A device needs a redirect address of its own.** An app cannot be sent back
  to a web page, so `nativeRedirectUri` and `desktopRedirectUri` in
  [assets/config.json](assets/config.json) have to be registered with the
  provider. Zitadel wants a native application for them rather than the web
  one: put its client id in `nativeClientId`, which the phone and desktop
  builds sign in as. Left out, they sign in as `clientId`.
- **The score can be written out as MusicXML, but not yet as a picture.** The
  old app exported the drawn SVG out of OSMD; the equivalent here would be
  writing what the engraver paints out as SVG, which has not been done.

## Running it

```bash
$ flutter run -d chrome --web-port=3000   # CHROME_EXECUTABLE=/usr/bin/chromium if needed
$ flutter run -d linux
$ flutter test
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

**Linux needs WebKitGTK 4.1 installed**, to build and to run. `flutter_web_auth_2`
depends on `desktop_webview_window`, whose Linux plugin links against it. The
app never opens that webview — on Linux the sign-in sends the browser to the
provider and catches the answer on a local port
([lib/features/auth/authorizer_native.dart](lib/features/auth/authorizer_native.dart))
— but the library is linked all the same, so without it the app does not even
start. To run the released bundle, install the runtime package
(`libwebkit2gtk-4.1-0` on Debian and Ubuntu) next to GTK 3; to build it,
`libwebkit2gtk-4.1-dev` on top of Flutter's own Linux prerequisites. The
release notes say the same.

**Windows needs nothing extra.** The Visual C++ runtime the app is built
against is copied next to `score.exe` by the build
([windows/CMakeLists.txt](windows/CMakeLists.txt)), so the zip runs on a
Windows that has never had the redistributable installed.

On both, **one copy of the app runs at a time**. Two would share one store
file and overwrite each other's unsent edits, so starting it again brings the
window that is already open to the front instead.

### Android is pinned to AGP 8

It builds, and it is pinned to get there. What is pinned is the Android Gradle
Plugin — [android/settings.gradle.kts](android/settings.gradle.kts) — and not
Flutter, which stays wherever the machine has it.

AGP 9 compiles Kotlin itself, and a plugin is meant to stop bringing its own
compiler when it sees one. The two plugins this app uses on Android disagree
about that:

| | applies its own Kotlin plugin |
|---|---|
| `file_picker` 11 | not under AGP 9 — it expects the built-in compiler |
| `flutter_web_auth_2` 5 | always |

Under AGP 9 there is no setting that suits both. Turn AGP's compiler on and the
second plugin collides with it; turn it off — which is what Flutter's template
does — and the first plugin's Kotlin is never compiled at all, so the generated
plugin registrant cannot find a class that was never built. That is the failure
this pin exists to avoid, and it is worth recognising by name:

```
GeneratedPluginRegistrant.java:19: error: cannot find symbol
  new com.mr.flutter.plugin.filepicker.FilePickerPlugin()
```

Under AGP 8 there is no built-in compiler to disagree about, both plugins bring
their own, and both build.

**Undoing the pin**, once `flutter_web_auth_2` learns to stand aside under AGP 9
the way `file_picker` already does:

1. `com.android.application` back to 9.x and Gradle back to 9.x
2. `android.builtInKotlin=true` in [android/gradle.properties](android/gradle.properties)
3. drop `org.jetbrains.kotlin.android` from
   [android/app/build.gradle.kts](android/app/build.gradle.kts) — AGP compiles
   `MainActivity.kt` itself from then on

Nothing in `lib/` is involved either way.

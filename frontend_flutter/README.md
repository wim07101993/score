# The frontend, in Flutter

The same app as [frontend/](../frontend), written once and run on the web, on a
desktop and on a phone. The old one is still there and still works; this is
beside it rather than instead of it.

The one thing that is not a translation is the score itself. The app it replaces
draws sheet music with [OpenSheetMusicDisplay](https://opensheetmusicdisplay.org),
which is JavaScript and only runs in a browser. This one draws it in Dart, so
what a player sees on a phone at a gig and what they see in a browser at home is
the same drawing, worked out by the same code.

## Drawing a score

```
lib/notation/
├── musicxml/        reading the document
│   ├── model.dart       what a score is, as far as drawing it goes
│   └── parser.dart      reading one, forgivingly
├── view/            reading it a different way
│   ├── pitch.dart       transposing a note, and the key it lands in
│   ├── score_view.dart  which parts are on screen, and how far it is moved
│   └── musicxml_view.dart   the document as the view has it
├── layout/          working out where everything goes
│   ├── staff_position.dart  where a note sits on a staff
│   ├── note_values.dart     what the note types are worth
│   └── engine.dart          spacing, systems, stems, beams, ties
└── render/          putting it on a canvas
    ├── smufl.dart       the glyphs, generated from the font's own metrics
    ├── primitives.dart  what a laid-out score is made of
    └── score_painter.dart
```

It reads in one direction. A document is parsed, the view is applied to it, the
result is laid out into a flat list of primitives — glyphs, lines, filled shapes,
curves, words — and the painter draws them at a scale. Every measurement the
layout makes is in **staff spaces**, the gap between two lines of a staff, and
what one is worth in pixels is decided only at the last step. That is what makes
zooming free, and it is what lets the whole engine be tested without a screen:
where a notehead ends up is a number in a list, which a test can read.

**Transposing is a change to the document, not to the drawing.** A view is
applied by rewriting the MusicXML — moving every note, every key signature and
every chord symbol — and then drawing what comes out. So the score on screen and
the file the download button produces are the same document, worked out once,
and there is no second implementation of what a transposed key is to disagree
with the first. It also means transposing can be undone, which is not true of
the app this replaces: OSMD rewrites the sheet it holds in memory, and asking it
for a transposition of zero again does not put the keys back.

### Light and dark

The app follows the machine unless the reader says otherwise in **Settings**,
which is remembered on the device and never sent anywhere: a tablet on a stand
and a laptop at home are set separately while being the same account.

The page a score is drawn on follows the app, and the two colours it is drawn
with are chosen **together** — `SheetPalette` in
[lib/notation/score_sheet.dart](lib/notation/score_sheet.dart) holds both, and
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

**A dark page is also what showed up a bug in the engine.** A staff line is an
eighth of a staff space, which at a readable zoom is about one pixel — and a
one-pixel line laid across the boundary between two pixels is not drawn as a
line. It is drawn as two rows at half cover, and half cover is half ink and half
page:

```
         ink   page     what a staff line came out as
bright   #000  #FFF     #808080   — still obviously a line
dimmed   #111  #939     #525356   — half way to the page: smoke
```

The noteheads are shapes several pixels across and land at full ink either way,
so on a dark page the notes stayed crisp while the staff under them dissolved —
and *which* of the five lines dissolved changed with every scroll and every zoom
step. On white it had been survivable for as long as the app had existed.

So `ScorePainter` puts a hairline where the screen can draw one: both edges on
whole device pixels, never thinner than one. It costs a fraction of a pixel of
position — across five lines the spacing can come out a pixel uneven — and buys
every line its edge back, on both pages. `test/notation/hairline_test.dart` reads
the pixels back to check.

**This is what lets the lamp go as low as it does.** Half way between a dim page
and its ink is nothing at all, so as long as staff lines were being drawn at half
strength, contrast had to be spent making up for it — which is how the first
attempts at a dark page ended up as glaring as they were. A staff line that is
simply *the ink* does not have to shout, and the dial can go down to 18% without
the staff going with it.

Both are drawn by [the preview](#seeing-what-it-draws), which uses the app's own
palettes rather than a black and a white of its own.

The glyphs are [Bravura](https://github.com/steinbergmedia/bravura), the
reference SMuFL font, under the SIL Open Font License. Only the hundred-odd
glyphs that are actually drawn are carried over, along with the metrics that say
how wide each one is and where a stem meets a notehead:

```bash
$ python3 scripts/gen_smufl.py lib/notation/render/smufl.dart
```

### Seeing what it draws

Whether a score is engraved well is a question for eyes, so there is a preview
that writes real scores to `build/preview` as pictures:

```bash
$ flutter test test/notation/render_preview_test.dart
```

It draws the two example scores the API's own tests use — a Beethoven song and a
Brahms one, both with a voice over a piano, several voices to a staff, chords,
beams, slurs, ties, lyrics and a clef change — as written, transposed, with a
part taken off the screen, and on a dark page.

## The rest of the app

```
lib/
├── config.dart      where the API is, and how a user proves who they are
├── app.dart         everything wired together once
├── data/            where things are kept, and how a file leaves the app
│   └── settings.dart    what this device prefers, which is not the account's
├── domains/         what the app knows, a directory per subject
│   ├── auth/            proving who the user is
│   ├── scores/          the scores and the documents behind them
│   └── sets/            the playlists a gig is played from
└── ui/              a file per page
```

A domain is an `api.dart` that speaks to the server, `models.dart` for what it
holds, and a `repository.dart` that is the only thing a page talks to. **A page
reads what is stored and asks for a sync; it never waits on the network to
draw.** A score is read on a stage and a set is edited at a gig, and both of
those are exactly where there is no network.

The rules a set is written under — what is queued, in what order it goes out,
and what happens when the server refuses — are the ones
[the old frontend's README](../README.md#the-sets) describes, and they are
ported rather than reinvented. A set owes the server three separate things in
order: what the set is, the songs added or moved, and how this player reads
them. Each is written against the one before it, so whatever did not get through
keeps what depends on it queued behind it.

## Where it differs from the app it replaces

- **Tokens survive a restart.** The old app kept them in `sessionStorage`, which
  lasts as long as a tab. A device that is closed and opened again at the next
  rehearsal should not ask the player to sign in again, and a refresh token that
  lives no longer than a tab never gets used.
- **A device needs a redirect address of its own.** An app cannot be sent back
  to a web page, so `nativeRedirectUri` in [assets/config.json](assets/config.json)
  has to be registered with the provider alongside the web one.
- **The score can be written out as MusicXML, but not yet as a picture.** The
  old app exported the drawn SVG out of OSMD; the equivalent here would be
  writing the primitives out as SVG, which has not been done.

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
[assets/config.json](assets/config.json), which is also the one the old frontend
is served from; the two cannot be running at once. The app says so and refuses
rather than leaving on a journey it cannot finish.

A desktop has no such problem: it listens on `desktopRedirectUri`'s port itself,
for as long as the sign-in takes, so there is nothing to line up by hand.

[assets/config.json](assets/config.json) is read at start-up rather than
compiled in, so the same build can be pointed at a development server and at a
real one.

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

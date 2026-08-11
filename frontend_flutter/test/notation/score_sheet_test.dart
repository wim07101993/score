import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/notation/render/score_painter.dart';
import 'package:score/notation/score_sheet.dart';

/// The sheet, asked what colour it is.
///
/// The app follows the machine, or whatever the reader chose in the settings.
/// The page follows the app. What must never follow anything on its own is one
/// half of the pair: ink that took the theme's word for it while the paper did
/// not is pale grey notes on white, which is legible in the way a photocopy of
/// a photocopy is legible — not on a stand, at a gig, in bad light.
///
/// So these are about the pair. Not "the ink is black", which was true until a
/// dark page was wanted, but that whichever page it is, what is drawn on it can
/// be read.

const _examples = '../test/example_data';

String _read(String name) => File('$_examples/$name').readAsStringSync();

ThemeData _themeOf(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B5BA5),
        brightness: brightness,
      ),
    );

/// The contrast between two opaque colours, the way the accessibility
/// guidelines reckon it: 21 for black on white, 1 for a colour on itself.
double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

/// What the sheet handed the painter, having been drawn under [brightness].
Future<({SheetPalette drawn, ScorePainter painter})> _sheet(
  WidgetTester tester,
  Brightness brightness,
) async {
  await tester.pumpWidget(
    MaterialApp(
      // A fresh tree per brightness. Handed the same one twice, MaterialApp
      // animates from one theme to the other, and a single pump lands partway
      // between the two — which is a real and welcome thing for a reader who
      // flips the setting, and a lie to a test that wants to know what dark
      // looks like.
      key: ValueKey(brightness),
      theme: _themeOf(brightness),
      home: Scaffold(
        body: ScoreSheet(musicXml: _read('BeetAnGeSample.musicxml')),
      ),
    ),
  );
  await tester.pump();

  final painter = tester
      .widget<CustomPaint>(find
          .descendant(
            of: find.byType(ScoreSheet),
            matching: find.byType(CustomPaint),
          )
          .first)
      .painter! as ScorePainter;

  final paper = tester
      .widget<ColoredBox>(find
          .descendant(
            of: find.byType(ScoreSheet),
            matching: find.byType(ColoredBox),
          )
          .first)
      .color;

  return (
    drawn: SheetPalette(
      paper: paper,
      ink: painter.ink,
      fadedInk: painter.fadedInk,
    ),
    painter: painter,
  );
}

void main() {
  group('the page and the ink on it', () {
    testWidgets('are far enough apart to read, on either theme',
        (tester) async {
      for (final brightness in Brightness.values) {
        final drawn = (await _sheet(tester, brightness)).drawn;

        // Above the 4.5 the accessibility guidelines ask of text, and
        // deliberately nowhere near as far apart on a dark page as on a white
        // one — see the group below.
        expect(
          _contrast(drawn.ink, drawn.paper),
          greaterThan(5),
          reason: 'the notes on a $brightness page',
        );
        // A grace note is drawn lighter, not drawn away. It is a mark that
        // means "lean on the next one", not something anybody reads at length,
        // so it is held to being *visible* rather than to what the guidelines
        // ask of text — and on a page with the lamp turned down there is less
        // to spend on it than on a white one.
        expect(
          _contrast(
            Color.alphaBlend(drawn.fadedInk, drawn.paper),
            drawn.paper,
          ),
          greaterThan(2.5),
          reason: 'the grace notes on a $brightness page',
        );
      }
    });

    testWidgets('are the pair the theme calls for, both of them', (tester) async {
      final light = (await _sheet(tester, Brightness.light)).drawn;
      final dark = (await _sheet(tester, Brightness.dark)).drawn;

      expect(light, SheetPalette.light);
      expect(dark, SheetPalette.dark);
      // The thing that went wrong: a page from one palette carrying ink from
      // the other.
      expect(light.paper, isNot(dark.paper));
      expect(light.ink, isNot(dark.ink));
    });
  });

  group('a dark page', () {
    test('is still ink on paper, not paper on ink', () {
      // The whole lesson, and what every earlier version of this got wrong. A
      // screen is not paper: paper gives back a share of the light in the room,
      // a screen makes its own and pushes it at the reader. In the dark the eye
      // opens up and anything bright on the screen blooms — and a white
      // notehead is both the bright thing and the thing being read. Dark marks
      // have no light to bloom with.
      expect(SheetPalette.dark.ink.computeLuminance(),
          lessThan(SheetPalette.dark.paper.computeLuminance()));
      expect(SheetPalette.light.ink.computeLuminance(),
          lessThan(SheetPalette.light.paper.computeLuminance()));
    });

    test('throws a fraction of the light a white page does', () {
      // Which is the whole of what "dark" buys, and the thing to keep hold of:
      // it is a page with the lamp turned down, and it has to stay turned down.
      expect(SheetPalette.dark.paper.computeLuminance(),
          lessThan(SheetPalette.light.paper.computeLuminance() / 2));
    });

    test('is nearer together than paper, having less room to work in', () {
      final dark = _contrast(SheetPalette.dark.ink, SheetPalette.dark.paper);
      final light = _contrast(SheetPalette.light.ink, SheetPalette.light.paper);

      expect(dark, lessThan(11));
      expect(dark, lessThan(light / 2));
    });

    test('fades a grace note less than paper does', () {
      // There is less contrast to spend, so less of it is spent.
      expect(SheetPalette.dark.fadedInk.a,
          greaterThan(SheetPalette.light.fadedInk.a));
    });
  });

  test('a page is asked for by brightness and never guessed at', () {
    expect(SheetPalette.forBrightness(Brightness.light), SheetPalette.light);
    expect(SheetPalette.forBrightness(Brightness.dark), SheetPalette.dark);
  });

  group('the lamp', () {
    test('full up is paper: white, black, and nothing else', () {
      final page = SheetPalette.lamp(brightness: SheetPalette.full);

      expect(page.paper, const Color(0xFFFFFFFF));
      expect(page.ink, const Color(0xFF000000));
      expect(page, SheetPalette.light);
    });

    test('is a share of the light a white page gives, not of a number', () {
      // What it is set to is what the page gives off, because that is what an
      // eye reckons by. Half way down the scale is a page throwing half the
      // light — a grey nearer #BCBCBC than the halfway #808080 — and a reader
      // dragging it feels an even dimming rather than a cliff at one end.
      for (final asked in [0.25, 0.5, 0.75, 1.0]) {
        final given = SheetPalette.lamp(brightness: asked).paper.computeLuminance();

        expect(given, closeTo(asked, 0.02), reason: 'asked for $asked');
      }
    });

    test('turns down evenly, and never turns itself back up', () {
      var last = 0.0;
      for (var step = 0; step <= 20; step++) {
        final lamp = SheetPalette.dimmest +
            step * (SheetPalette.full - SheetPalette.dimmest) / 20;
        final given =
            SheetPalette.lamp(brightness: lamp).paper.computeLuminance();

        expect(given, greaterThan(last), reason: 'at $lamp');
        last = given;
      }
    });

    test('is ink on paper at every setting, and readable at all of them', () {
      for (var step = 0; step <= 10; step++) {
        final lamp = SheetPalette.dimmest +
            step * (SheetPalette.full - SheetPalette.dimmest) / 10;
        final page = SheetPalette.lamp(brightness: lamp, warmth: 0.5);

        expect(page.ink.computeLuminance(),
            lessThan(page.paper.computeLuminance()),
            reason: 'ink on paper at $lamp');
        expect(_contrast(page.ink, page.paper), greaterThan(4),
            reason: 'readable at $lamp');
      }
    });

    test('will not be turned below what can be read off', () {
      final toolow = SheetPalette.lamp(brightness: 0.0);
      final toohigh = SheetPalette.lamp(brightness: 4);

      expect(toolow, SheetPalette.lamp(brightness: SheetPalette.dimmest));
      expect(toohigh, SheetPalette.lamp(brightness: SheetPalette.full));
    });

    test('warmth takes away blue rather than adding light', () {
      final cool = SheetPalette.lamp(brightness: 0.4);
      final warm = SheetPalette.lamp(brightness: 0.4, warmth: 1);

      expect(warm.paper.b, lessThan(cool.paper.b));
      expect(warm.paper.r, greaterThan(cool.paper.r));
      // The lamp is still where it was left: warmth is a separate dial, and one
      // that moved the other would be a dial nobody could set.
      expect(warm.paper.computeLuminance(),
          closeTo(cool.paper.computeLuminance(), 0.02));
    });

    test('a warm page is not written on in blue-black', () {
      // Ink that stayed cool on a warm page reads as a hole in it.
      final warm = SheetPalette.lamp(brightness: 0.3, warmth: 1);

      expect(warm.ink.r, greaterThan(warm.ink.b));
    });
  });
}

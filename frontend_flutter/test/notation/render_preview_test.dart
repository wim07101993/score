import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/notation/layout/engine.dart';
import 'package:score/notation/musicxml/parser.dart';
import 'package:score/notation/parts.dart';
import 'package:score/notation/render/score_painter.dart';
import 'package:score/notation/score_sheet.dart';
import 'package:score/notation/view/musicxml_view.dart';
import 'package:score/notation/view/score_view.dart';

/// Draws the example scores to files, so that a change to the engine can be
/// looked at rather than only asserted about.
///
/// It is a development tool rather than a test of anything: what it writes into
/// `build/preview` is a picture, and whether the picture is right is a question
/// for eyes. It is kept here because it needs a rendering surface, and that is
/// what the test harness is.
///
/// The whole score is drawn rather than as much of it as fits a screen — the
/// point is to see the last system as well as the first.
///
/// ```
/// $ flutter test test/notation/render_preview_test.dart
/// ```

const _examples = '../test/example_data';

/// How dense the pictures are. Anything above one is a screen a phone or a
/// laptop actually has, and it is also what tells the painter where the pixels
/// of these pictures are.
const _pixelRatio = 1.5;
const _output = 'build/preview';

/// A latin font, so that the words are words rather than the boxes the test
/// harness draws by default. Any of these will do; the first one there is, is
/// used, and if there is none the music is still drawn.
const _textFontCandidates = [
  '/usr/share/fonts/noto/NotoSans-Regular.ttf',
  '/usr/share/fonts/liberation/LiberationSerif-Regular.ttf',
  '/usr/share/fonts/TTF/DejaVuSans.ttf',
];

String? _textFont;

Future<void> _loadFonts() async {
  final music = FontLoader('Bravura')
    ..addFont(Future.value(
        ByteData.view(File('assets/fonts/Bravura.otf').readAsBytesSync().buffer)));
  await music.load();

  for (final path in _textFontCandidates) {
    if (!File(path).existsSync()) continue;
    final text = FontLoader('PreviewText')
      ..addFont(
          Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
    await text.load();
    _textFont = 'PreviewText';
    return;
  }
}

void main() {
  setUpAll(_loadFonts);

  Future<void> draw(
    WidgetTester tester, {
    required String file,
    required String source,
    ScoreView? view,
    double width = 1200,
    double space = 8.0,
    SheetPalette? palette,
  }) async {
    // The app's own colours rather than a black and a white chosen here. A
    // preview drawn in ink the app does not use is a preview of nothing.
    final sheet = palette ?? SheetPalette.light;
    const margin = 16.0;
    final widthSp = (width - 2 * margin) / space;

    final score = parseMusicXmlDocument(documentForView(source, view));
    final drawing = layoutScore(score, LayoutOptions(width: widthSp));
    final height = drawing.height * space + 2 * margin;

    await tester.binding.setSurfaceSize(Size(width, height));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, fontFamily: _textFont),
      home: RepaintBoundary(
        key: key,
        child: Container(
          color: sheet.paper,
          padding: const EdgeInsets.all(margin),
          child: CustomPaint(
            size: Size(width - 2 * margin, drawing.height * space),
            painter: ScorePainter(
              drawing: drawing,
              space: space,
              ink: sheet.ink,
              fadedInk: sheet.fadedInk,
              // The density these are captured at, so the hairlines are put
              // where the *picture* has pixels rather than where a screen would.
              devicePixelRatio: _pixelRatio,
              textFont: _textFont,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      Directory(_output).createSync(recursive: true);
      File('$_output/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    // A score that draws nothing is a failure however pretty the file looks.
    expect(drawing.prims, isNotEmpty);
    expect(drawing.height, greaterThan(0));
  }

  testWidgets('the Beethoven, as it was written', (tester) async {
    await draw(
      tester,
      file: 'beethoven.png',
      source: File('$_examples/BeetAnGeSample.musicxml').readAsStringSync(),
    );
  });

  testWidgets('the Brahms, as it was written', (tester) async {
    await draw(
      tester,
      file: 'brahms.png',
      source: File('$_examples/BrahWiMeSample.musicxml').readAsStringSync(),
    );
  });

  testWidgets('the Brahms, transposed down a major third', (tester) async {
    final source = File('$_examples/BrahWiMeSample.musicxml').readAsStringSync();
    final parts = readParts(parseMusicXml(source)).map((p) => p.id).toList();

    await draw(
      tester,
      file: 'brahms-transposed.png',
      source: source,
      view: ScoreView.forParts(parts).withTransposition(-4),
    );
  });

  testWidgets('the Brahms, close up', (tester) async {
    // Big enough to see whether a stem meets its notehead and whether a beam
    // sits where it should, which is not a question a whole page can answer.
    await draw(
      tester,
      file: 'brahms-close.png',
      source: File('$_examples/BrahWiMeSample.musicxml').readAsStringSync(),
      width: 1500,
      space: 20,
    );
  });

  testWidgets('the Brahms, in a dark room', (tester) async {
    // The one that has to be looked at rather than asserted about: whether the
    // staff lines hold together at this weight against a dark page, and whether
    // the ink glows, are questions for eyes.
    await draw(
      tester,
      file: 'brahms-dark.png',
      source: File('$_examples/BrahWiMeSample.musicxml').readAsStringSync(),
      palette: SheetPalette.dark,
    );
  });

  testWidgets('the Brahms, in a dark room, close up', (tester) async {
    await draw(
      tester,
      file: 'brahms-dark-close.png',
      source: File('$_examples/BrahWiMeSample.musicxml').readAsStringSync(),
      width: 1500,
      space: 20,
      palette: SheetPalette.dark,
    );
  });

  testWidgets('the Beethoven, with the piano off the screen', (tester) async {
    final source = File('$_examples/BeetAnGeSample.musicxml').readAsStringSync();
    final parts = readParts(parseMusicXml(source)).map((p) => p.id).toList();

    await draw(
      tester,
      file: 'beethoven-one-part.png',
      source: source,
      view: ScoreView.forParts(parts).withPartVisible(parts.last, false),
    );
  });
}

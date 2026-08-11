import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/notation/render/primitives.dart';
import 'package:score/notation/render/score_painter.dart';

/// Where a staff line lands.
///
/// A staff line is an eighth of a staff space thick, which at a readable zoom is
/// about one pixel, and a one-pixel line laid across the boundary between two
/// pixels is not drawn as a line: it is drawn as two rows of half-covered
/// pixels. Half-covered means half ink and half page.
///
/// On white that survives — half of black on white is a grey that still reads as
/// a line, which is why this went unnoticed for as long as there was only a
/// white page. On a dark one it does not: the noteheads are several pixels
/// across and land at full ink, the staff lines land at half, and half way
/// between a near-black page and a near-white ink is a mid grey. The notes stay
/// crisp and the staff they sit on turns to smoke.
///
/// These are about the pixels, because that is where it happens.

/// The rows of [image], as the average brightness of each.
Future<List<double>> _rows(ui.Image image) async {
  final data = (await image.toByteData())!.buffer.asUint8List();
  return [
    for (var y = 0; y < image.height; y++)
      List.generate(image.width, (x) => data[(y * image.width + x) * 4])
              .reduce((a, b) => a + b) /
          image.width,
  ];
}

/// One horizontal line at [y] staff spaces, drawn white on black.
Future<ui.Image> _draw(double y, {double devicePixelRatio = 1.0}) async {
  const space = 8.0;
  const width = 40.0;
  const height = 20.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(devicePixelRatio);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..color = Colors.black,
  );

  ScorePainter(
    drawing: ScoreDrawing(
      // An eighth of a staff space, the thickness a staff line is engraved at.
      prims: [LinePrim(0, y, width / space, y, 0.125)],
      width: width / space,
      height: height / space,
    ),
    space: space,
    ink: Colors.white,
    fadedInk: Colors.white,
    devicePixelRatio: devicePixelRatio,
  ).paint(canvas, const Size(width, height));

  return recorder.endRecording().toImage(
        (width * devicePixelRatio).round(),
        (height * devicePixelRatio).round(),
      );
}

void main() {
  // What matters is where a line's *edges* fall, not its middle. A line one
  // pixel thick whose middle sits on a whole pixel has its edges on two halves,
  // which is the case that smears; a line whose middle sits between two pixels
  // has its edges on whole ones, and was always drawn correctly.

  test('a line whose edges fall between pixels is drawn on one of them',
      () async {
    // 1.25 staff spaces at 8 pixels to the space is 10 pixels, so a line an
    // eighth of a space thick runs from 9.5 to 10.5: half of one row and half
    // of the next, which is the smear this exists to stop.
    final rows = await _rows(await _draw(1.25));

    final inked = rows.where((row) => row > 1).toList();
    expect(inked, isNotEmpty, reason: 'the line is drawn at all');
    expect(inked.length, 1, reason: 'on one row, not smeared across two');
    expect(inked.single, greaterThan(250), reason: 'at full ink');
  });

  test('a line already on whole pixels is left exactly where it was', () async {
    // 9.5 pixels, so the line runs from 9.0 to 10.0 — already a row of its own,
    // and moving it would be moving it for nothing.
    final rows = await _rows(await _draw(1.1875));

    expect(rows.where((row) => row > 1).length, 1);
    expect(rows.indexWhere((row) => row > 1), 9);
  });

  test('wherever it falls, it is never half a line', () async {
    // Every eighth of a pixel through a whole one. Nothing in between should
    // ever come out grey.
    for (var step = 0; step < 8; step++) {
      final rows = await _rows(await _draw(1.0 + step / 64));
      final inked = rows.where((row) => row > 1).toList();

      expect(inked.length, 1, reason: 'at 1 + $step/64 spaces');
      expect(inked.single, greaterThan(250), reason: 'at 1 + $step/64 spaces');
    }
  });

  test('a screen with pixels to spare gets the thinner line it can draw',
      () async {
    // Two device pixels to the logical one: the line is a whole device pixel,
    // which is half of what it would have to be on a coarser screen.
    final rows = await _rows(await _draw(1.1875, devicePixelRatio: 2));
    final inked = rows.where((row) => row > 1).toList();

    expect(inked.length, 2, reason: 'a staff line is 2 device pixels at 2x');
    expect(inked.every((row) => row > 250), isTrue, reason: 'both at full ink');
  });
}

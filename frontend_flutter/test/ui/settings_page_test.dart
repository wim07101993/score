import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/data/settings.dart';
import 'package:score/notation/score_sheet.dart';
import 'package:score/ui/settings_page.dart';

/// Setting the theme, and lighting the page.
///
/// What is stored and what it means are [Settings]' business and are tested
/// there. What is left here is the part a finger touches: that the answers are
/// all on offer, that what is in force is what is shown, and that moving
/// something says so.

Future<void> _show(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.system,
  Brightness brightness = Brightness.dark,
  PageLook look = (brightness: 0.29, warmth: 0.3),
  ValueChanged<ThemeMode>? onModeChanged,
  ValueChanged<PageLook>? onLookChanged,
  VoidCallback? onLookReset,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Appearance(
        mode: mode,
        onModeChanged: onModeChanged ?? (_) {},
        brightness: brightness,
        look: look,
        onLookChanged: onLookChanged ?? (_) {},
        onLookReset: onLookReset,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Whether the tile carrying [label] is the one with the dot in it.
bool _isChosen(WidgetTester tester, String label) {
  final tile = tester.widget<RadioListTile<ThemeMode>>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(RadioListTile<ThemeMode>),
    ),
  );
  return tile.value ==
      tester
          .widget<RadioGroup<ThemeMode>>(find.byType(RadioGroup<ThemeMode>))
          .groupValue;
}

Slider _slider(WidgetTester tester, String label) =>
    tester.widget<Slider>(find.byKey(dialKey(label)));

void main() {
  group('choosing a theme', () {
    testWidgets('all three answers are there to be chosen', (tester) async {
      await _show(tester);

      expect(find.text('Follow the system'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('the one in force is the one shown as chosen', (tester) async {
      await _show(tester, mode: ThemeMode.dark);

      expect(_isChosen(tester, 'Dark'), isTrue);
      expect(_isChosen(tester, 'Light'), isFalse);
      expect(_isChosen(tester, 'Follow the system'), isFalse);
    });

    testWidgets('touching an answer says so, once, with what was touched',
        (tester) async {
      final said = <ThemeMode>[];
      await _show(tester, onModeChanged: said.add);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(said, [ThemeMode.dark]);
    });
  });

  group('lighting the page', () {
    testWidgets('says which page is being lit', (tester) async {
      await _show(tester, brightness: Brightness.dark);
      expect(find.text('The page, in the dark'), findsOneWidget);

      await _show(tester, brightness: Brightness.light);
      expect(find.text('The page, in the light'), findsOneWidget);
    });

    testWidgets('both dials show what they are set to', (tester) async {
      await _show(tester, look: (brightness: 0.5, warmth: 0.25));

      expect(_slider(tester, 'Brightness').value, 0.5);
      expect(_slider(tester, 'Warmth').value, 0.25);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('the brightness dial stops where a page stops being readable',
        (tester) async {
      await _show(tester);

      final dial = _slider(tester, 'Brightness');
      expect(dial.min, SheetPalette.dimmest);
      expect(dial.max, SheetPalette.full);
    });

    testWidgets('moving one dial leaves the other where it was',
        (tester) async {
      final said = <PageLook>[];
      await _show(
        tester,
        look: (brightness: 0.5, warmth: 0.25),
        onLookChanged: said.add,
      );

      _slider(tester, 'Brightness').onChanged!(0.8);
      expect(said.single.brightness, 0.8);
      expect(said.single.warmth, 0.25, reason: 'the warmth was not touched');

      said.clear();
      _slider(tester, 'Warmth').onChanged!(0.6);
      expect(said.single.warmth, 0.6);
      expect(said.single.brightness, 0.5, reason: 'the lamp was not touched');
    });

    testWidgets('there is nothing to put back until something is changed',
        (tester) async {
      await _show(tester);
      expect(
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Reset')).onPressed,
        isNull,
      );

      var reset = 0;
      await _show(tester, onLookReset: () => reset++);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(reset, 1);
    });

    testWidgets('the page it is describing is drawn in the palette it is set to',
        (tester) async {
      await _show(tester, look: (brightness: 0.29, warmth: 0.3));

      final shown = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((box) => box.color)
          .toList();
      final wanted =
          SheetPalette.lamp(brightness: 0.29, warmth: 0.3).paper;

      expect(shown, contains(wanted));
    });
  });
}

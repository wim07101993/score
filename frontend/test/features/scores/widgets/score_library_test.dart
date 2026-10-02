import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/widgets/score_library.dart';

/// A piece of a list: a score, or something written down without one.
typedef _Item = ({Score? score, String note});

final _items = <_Item>[
  for (var i = 0; i < 10; i++)
    (
      score: Score(
        id: '$i',
        work: Work(title: 'Piece $i'),
        creators: Creators(composers: ['Composer ${i % 9}']),
      ),
      note: '',
    ),
  (score: null, note: 'Never scanned'),
];

Future<void> _show(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ScoreLibrary<_Item>(
        items: _items,
        scoreOf: (item) => item.score,
        textOf: (item) => item.note,
        itemBuilder: (context, item) =>
            Text(item.score?.title ?? item.note),
        empty: 'Nothing at all.',
      ),
    ),
  ));
}

void main() {
  testWidgets('the filters are beside the list where there is room',
      (tester) async {
    await _show(tester, const Size(1200, 900));

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('1 more'), findsOneWidget);
    expect(find.text('Never scanned'), findsOneWidget);

    await tester.tap(find.text('Composer 0'));
    await tester.pump();

    expect(find.text('Filters (1)'), findsOneWidget);
    expect(find.text('Piece 0'), findsOneWidget);
    expect(find.text('Piece 1'), findsNothing);
    // Nothing to tick it by, so nothing ticked lets it through.
    expect(find.text('Never scanned'), findsNothing);

    await tester.tap(find.text('Clear all'));
    await tester.pump();
    expect(find.text('Never scanned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the filters fold away above the list where there is not',
      (tester) async {
    await _show(tester, const Size(400, 900));

    expect(find.text('Composer 0'), findsNothing);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Composer 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('something without a score is found by what it says',
      (tester) async {
    await _show(tester, const Size(1200, 900));

    await tester.enterText(find.byType(TextField), 'scanned');
    await tester.pump();

    expect(find.text('Never scanned'), findsOneWidget);
    expect(find.text('Piece 0'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing like it');
    await tester.pump();
    expect(find.text('Nothing here matches that.'), findsOneWidget);
  });
}

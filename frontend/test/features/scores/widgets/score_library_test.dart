import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/models/creators.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/work.dart';
import 'package:score/features/scores/widgets/score_list/score_library.dart';

final _scores = [
  for (var i = 0; i < 10; i++)
    Score(
      id: '$i',
      work: Work(title: 'Piece $i'),
      creators: Creators(composers: ['Composer ${i % 9}']),
      lastChangedAt: Score.defaultLastChangedAt,
    ),
];

Future<List<Score>> _show(
  WidgetTester tester,
  Size size, {
  List<Score>? scores,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final tapped = <Score>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScoreLibrary(
          scores: scores ?? _scores,
          onScoreTapped: tapped.add,
          empty: 'Nothing at all.',
          header: const [Text('Above')],
        ),
      ),
    ),
  );
  return tapped;
}

void main() {
  testWidgets('the filters are beside the list where there is room', (
    tester,
  ) async {
    await _show(tester, const Size(1200, 900));

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Show 1 more'), findsOneWidget);
    expect(find.text('Above'), findsOneWidget);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Composer 1'));
    await tester.pump();

    expect(find.text('Filters (1)'), findsOneWidget);
    expect(find.text('Piece 1'), findsOneWidget);
    expect(find.text('Piece 2'), findsNothing);

    await tester.tap(find.text('Clear all'));
    await tester.pump();
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Piece 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the filters fold away above the list where there is not', (
    tester,
  ) async {
    await _show(tester, const Size(400, 900));

    expect(find.widgetWithText(CheckboxListTile, 'Composer 1'), findsNothing);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Composer 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('what is typed narrows the list', (tester) async {
    await _show(tester, const Size(1200, 900));

    await tester.enterText(find.byType(TextField), 'piece 3');
    await tester.pump();
    expect(find.text('Piece 3'), findsOneWidget);
    expect(find.text('Piece 4'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing like it');
    await tester.pump();
    expect(find.text('Nothing here matches that.'), findsOneWidget);
  });

  testWidgets('says so when there is nothing to list at all', (tester) async {
    await _show(tester, const Size(1200, 900), scores: []);

    expect(find.text('Nothing at all.'), findsOneWidget);
  });

  testWidgets('a tapped score is handed back', (tester) async {
    final tapped = await _show(tester, const Size(1200, 900));

    await tester.tap(find.text('Piece 2'));

    expect(tapped.map((score) => score.id), ['2']);
  });
}

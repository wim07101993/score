import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/sets/widgets/entry_description_field.dart';

/// The note next to a song takes on what a sync brings in, as long as nobody
/// has touched it — and leaving it untouched is not a write.
void main() {
  Future<void> pumpField(
    WidgetTester tester,
    String note,
    List<String> submitted,
  ) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            EntryDescriptionField(
              initialValue: note,
              enabled: true,
              onSubmitted: submitted.add,
            ),
            // Somewhere for the focus to go when the field is left.
            const TextField(key: Key('elsewhere')),
          ],
        ),
      ),
    ),
  );

  testWidgets(
    'shows a note a sync changed, and does not write the old one back',
    (tester) async {
      final submitted = <String>[];
      await pumpField(tester, 'A', submitted);
      await pumpField(tester, 'B', submitted);

      expect(find.text('B'), findsOneWidget);
      expect(find.text('A'), findsNothing);

      await tester.tap(find.byType(EntryDescriptionField));
      await tester.pump();
      await tester.tap(find.byKey(const Key('elsewhere')));
      await tester.pump();

      expect(submitted, isEmpty);
    },
  );

  testWidgets('keeps what the player is typing over what a sync brings in', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpField(tester, 'A', submitted);
    await tester.enterText(find.byType(EntryDescriptionField), 'mine');
    await pumpField(tester, 'B', submitted);

    expect(find.text('mine'), findsOneWidget);

    await tester.tap(find.byKey(const Key('elsewhere')));
    await tester.pump();

    expect(submitted, ['mine']);
  });
}

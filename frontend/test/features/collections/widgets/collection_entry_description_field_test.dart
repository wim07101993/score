import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/collections/widgets/collection_entry_description_field.dart';

/// What is written next to a piece takes on what a sync brings in, as long as
/// nobody has touched it — and leaving it untouched is not a write.
void main() {
  Future<void> pumpField(
    WidgetTester tester,
    String text,
    List<String> submitted, {
    bool isTheOnlyName = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            CollectionEntryDescriptionField(
              initialValue: text,
              isTheOnlyName: isTheOnlyName,
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

  for (final isTheOnlyName in [false, true]) {
    testWidgets(
      'shows what a sync changed, and does not write the old text back'
      '${isTheOnlyName ? ' (a piece with no score)' : ''}',
      (tester) async {
        final submitted = <String>[];
        await pumpField(tester, 'A', submitted, isTheOnlyName: isTheOnlyName);
        await pumpField(tester, 'B', submitted, isTheOnlyName: isTheOnlyName);

        expect(find.text('B'), findsOneWidget);
        expect(find.text('A'), findsNothing);

        await tester.tap(find.byType(CollectionEntryDescriptionField));
        await tester.pump();
        await tester.tap(find.byKey(const Key('elsewhere')));
        await tester.pump();

        expect(submitted, isEmpty);
      },
    );
  }

  testWidgets('keeps what the player is typing over what a sync brings in', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpField(tester, 'A', submitted);
    await tester.enterText(
      find.byType(CollectionEntryDescriptionField),
      'mine',
    );
    await pumpField(tester, 'B', submitted);

    expect(find.text('mine'), findsOneWidget);

    await tester.tap(find.byKey(const Key('elsewhere')));
    await tester.pump();

    expect(submitted, ['mine']);
  });
}

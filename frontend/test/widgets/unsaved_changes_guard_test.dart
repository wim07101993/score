import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/widgets/unsaved_changes_guard.dart';

/// A page with edits that are not saved asks before it is left.
void main() {
  Future<void> openPage(WidgetTester tester, {required bool unsaved}) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => UnsavedChangesGuard(
              unsaved: unsaved,
              child: const Scaffold(body: Text('the set')),
            ),
          )),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('leaves at once when nothing is unsaved', (tester) async {
    await openPage(tester, unsaved: false);
    await goBack(tester);

    expect(find.text('the set'), findsNothing);
  });

  testWidgets('asks, and stays when the player keeps editing', (tester) async {
    await openPage(tester, unsaved: true);
    await goBack(tester);

    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('the set'), findsOneWidget);
  });

  testWidgets('asks, and leaves when the player says so', (tester) async {
    await openPage(tester, unsaved: true);
    await goBack(tester);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('the set'), findsNothing);
  });
}

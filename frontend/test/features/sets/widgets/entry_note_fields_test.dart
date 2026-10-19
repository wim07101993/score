import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/collections/widgets/collection_entry_description_field.dart';
import 'package:score/features/sets/widgets/entry_description_field.dart';

/// The note next to a song of a set, or a piece of a collection, typed and
/// then left by tapping "done": on a phone that tap does not take the focus
/// off the field, and the field is gone before it would hear.
///
/// The page is the shape of the set and collection pages: a "done" button
/// that swaps the list the field is in for an overview without it.
class const _Page({
  required final List<String> submitted,
  required final bool collection,
}) extends StatefulWidget {
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  bool _editing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Done changing it',
              icon: const Icon(Icons.check),
              onPressed: () => setState(() => _editing = false),
            ),
        ],
      ),
      body: !_editing
          ? const Text('overview')
          : ListView(
              children: [
                if (widget.collection)
                  CollectionEntryDescriptionField(
                    initialValue: '',
                    enabled: true,
                    onSubmitted: widget.submitted.add,
                  )
                else
                  EntryDescriptionField(
                    initialValue: '',
                    enabled: true,
                    onSubmitted: widget.submitted.add,
                  ),
              ],
            ),
    );
  }
}

void main() {
  for (final collection in [false, true]) {
    final field = collection
        ? CollectionEntryDescriptionField
        : EntryDescriptionField;

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets('$field keeps what was typed when "done" is tapped on '
          '$platform', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          final submitted = <String>[];
          await tester.pumpWidget(
            MaterialApp(
              home: _Page(submitted: submitted, collection: collection),
            ),
          );
          await tester.tap(find.byType(field));
          await tester.enterText(find.byType(field), 'capo 2');
          await tester.pump();

          // A finger, which is what does not take the focus with it.
          await tester.tap(find.byTooltip('Done changing it'));
          await tester.pumpAndSettle();

          expect(find.text('overview'), findsOneWidget);
          expect(submitted, ['capo 2']);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    testWidgets('$field writes nothing when nothing was typed', (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: _Page(submitted: submitted, collection: collection),
        ),
      );
      await tester.tap(find.byTooltip('Done changing it'));
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
    });
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/scores/widgets/upload_score_button.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/router.dart';

import '../../../test_get_it.dart';

const _viewer = {
  'sub': 'player',
  'roles': {'score_viewer': <String, dynamic>{}},
};

/// The app opened at [route] alone, as [router] has it.
Widget _app(AppRouter router, PageRouteInfo route) => MaterialApp.router(
  routerConfig: router.config(deepLinkBuilder: (_) => DeepLink([route])),
);

ScoreSet _set({
  required String id,
  required List<SetEntry> entries,
}) => ScoreSet(
  id: id,
  title: 'Friday',
  description: '',
  entries: entries,
  sharedWith: const [],
  isOwner: true,
  lastChangedAt: DateTime.utc(2026),
);

void main() {
  tearDown(() => GetIt.I.popScope());

  testWidgets('an editor who may not read scores can still upload one', (
    tester,
  ) async {
    await tester.runAsync(
      () => GetIt.I.registerForTesting(
        user: const {
          'sub': 'librarian',
          'roles': {'score_editor': <String, dynamic>{}},
        },
      ),
    );

    await tester.pumpWidget(_app(AppRouter(), ScoreRoute(scoreId: 'new')));
    await tester.pump();

    expect(find.byType(UploadScoreButton), findsOneWidget);
    expect(find.text('Scores are for score viewers.'), findsNothing);
  });

  group('a song of a set on the stand', () {
    late AppRouter router;
    late String setId;
    late String entryId;

    Future<void> openPaperEntry(WidgetTester tester) async {
      await tester.runAsync(() => GetIt.I.registerForTesting(user: _viewer));
      setId = 'friday';
      entryId = 'birthday';
      await tester.runAsync(
        () => GetIt.I<SetsDatabase>().put(
          _set(
            id: setId,
            entries: [
              SetEntry(
                id: entryId,
                scoreId: null,
                description: 'Happy birthday',
                transposition: 0,
              ),
            ],
          ),
        ),
      );
      router = AppRouter();
      await tester.pumpWidget(
        _app(router, paperRoute(setId: setId, entryId: entryId)),
      );
      // The router puts the page up a frame later, and the page reads what it
      // is of after that.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      await tester.pump();
      expect(find.text('This one is played from paper.'), findsOneWidget);
    }

    testWidgets('taken out of the set is no longer shown as in it', (
      tester,
    ) async {
      await openPaperEntry(tester);

      await tester.runAsync(() async {
        await GetIt.I<SetsDatabase>().put(_set(id: setId, entries: const []));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(find.text('This song is no longer in there.'), findsOneWidget);
    });

    testWidgets('scanned while it is open is opened as its score, in the set', (
      tester,
    ) async {
      await openPaperEntry(tester);

      await tester.runAsync(() async {
        await GetIt.I<SetsDatabase>().put(
          _set(
            id: setId,
            entries: [
              SetEntry(
                id: entryId,
                scoreId: 'scanned',
                description: 'Happy birthday',
                transposition: 0,
              ),
            ],
          ),
        );
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(
        router.currentUrl,
        router.pathOf(
          PerformScoreRoute(scoreId: 'scanned', setId: setId, entryId: entryId),
        ),
      );
      // In its place, rather than on top of it.
      expect(router.stack, hasLength(1));
      await tester.pump(const Duration(minutes: 1));
    });
  });
}

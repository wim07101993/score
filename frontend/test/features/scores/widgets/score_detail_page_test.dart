import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/scores/widgets/upload_score_button.dart';
import 'package:score/features/sets/repository.dart';
import 'package:score/router.dart';

import '../../../test_get_it.dart';

const _viewer = UserInfo(
  subject: 'player',
  roles: {'score_viewer': <String, dynamic>{}},
);

/// The app opened at [route] alone, as [router] has it.
Widget _app(AppRouter router, PageRouteInfo route) => MaterialApp.router(
      routerConfig: router.config(deepLinkBuilder: (_) => DeepLink([route])),
    );

void main() {
  tearDown(() => GetIt.I.popScope());

  testWidgets('an editor who may not read scores can still upload one',
      (tester) async {
    await tester.runAsync(() => GetIt.I.registerForTesting(
          user: const UserInfo(
            subject: 'librarian',
            roles: {'score_editor': <String, dynamic>{}},
          ),
        ));

    await tester.pumpWidget(_app(AppRouter(), ScoreRoute(scoreId: 'new')));
    await tester.pump();

    expect(find.byType(UploadScoreButton), findsOneWidget);
    expect(find.text('Scores are for score viewers.'), findsNothing);
  });

  group('a song of a set on the stand', () {
    late SetsRepository sets;
    late AppRouter router;
    late String setId;
    late String entryId;

    Future<void> openPaperEntry(WidgetTester tester) async {
      await tester.runAsync(() => GetIt.I.registerForTesting(user: _viewer));
      sets = GetIt.I<SetsRepository>();
      await tester.runAsync(() async {
        final set = await sets.saveSet(title: 'Friday');
        final withEntry =
            await sets.saveEntry(set.id, description: 'Happy birthday');
        setId = set.id;
        entryId = withEntry.entries.single.id;
      });
      router = AppRouter();
      await tester.pumpWidget(
        _app(router, paperRoute(setId: setId, entryId: entryId)),
      );
      // The router puts the page up a frame later, and the page reads what it
      // is of after that.
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text('This one is played from paper.'), findsOneWidget);
    }

    testWidgets('taken out of the set is no longer shown as in it',
        (tester) async {
      await openPaperEntry(tester);

      await tester.runAsync(() => sets.deleteEntry(setId, entryId));
      await tester.pump();

      expect(find.text('This song is no longer in there.'), findsOneWidget);
    });

    testWidgets('scanned while it is open is opened as its score, in the set',
        (tester) async {
      await openPaperEntry(tester);

      await tester.runAsync(
          () => sets.saveEntry(setId, id: entryId, scoreId: 'scanned'));
      await tester.pump();

      expect(
        router.currentUrl,
        router.pathOf(
          PerformScoreRoute(scoreId: 'scanned', setId: setId, entryId: entryId),
        ),
      );
      // In its place, rather than on top of it.
      expect(router.stack, hasLength(1));
    });
  });
}

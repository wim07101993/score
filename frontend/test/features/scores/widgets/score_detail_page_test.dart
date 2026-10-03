import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/app.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/scores/widgets/score_detail_page.dart';
import 'package:score/features/scores/widgets/upload_score_button.dart';
import 'package:score/routes.dart';

const _viewer = UserInfo(
  subject: 'player',
  roles: {'score_viewer': <String, dynamic>{}},
);

/// The page on its own, over [app], with every page it opens in place of
/// itself written down in [opened].
Widget _page(App app, Widget page, List<String> opened) => AppScope(
      app: app,
      child: MaterialApp(
        home: page,
        onGenerateRoute: (settings) {
          opened.add(settings.name!);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('opened')),
          );
        },
      ),
    );

void main() {
  testWidgets('an editor who may not read scores can still upload one',
      (tester) async {
    final app = (await tester.runAsync(() => App.forTesting(
          user: const UserInfo(
            subject: 'librarian',
            roles: {'score_editor': <String, dynamic>{}},
          ),
        )))!;

    await tester.pumpWidget(
        _page(app, const ScoreDetailPage(scoreId: 'new'), []));
    await tester.pump();

    expect(find.byType(UploadScoreButton), findsOneWidget);
    expect(find.text('Scores are for score viewers.'), findsNothing);
  });

  group('a song of a set on the stand', () {
    late App app;
    late String setId;
    late String entryId;

    Future<void> openPaperEntry(WidgetTester tester, List<String> opened) async {
      app = (await tester.runAsync(() => App.forTesting(user: _viewer)))!;
      await tester.runAsync(() async {
        final set = await app.sets.saveSet(title: 'Friday');
        final withEntry =
            await app.sets.saveEntry(set.id, description: 'Happy birthday');
        setId = set.id;
        entryId = withEntry.entries.single.id;
      });
      await tester.pumpWidget(_page(
        app,
        ScoreDetailPage(
          scoreId: ScoreDetailRoute.paper,
          setId: setId,
          entryId: entryId,
          performing: true,
        ),
        opened,
      ));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text('This one is played from paper.'), findsOneWidget);
    }

    testWidgets('taken out of the set is no longer shown as in it',
        (tester) async {
      await openPaperEntry(tester, []);

      await tester.runAsync(() => app.sets.deleteEntry(setId, entryId));
      await tester.pump();

      expect(find.text('This song is no longer in there.'), findsOneWidget);
    });

    testWidgets('scanned while it is open is opened as its score, in the set',
        (tester) async {
      final opened = <String>[];
      await openPaperEntry(tester, opened);

      await tester.runAsync(
          () => app.sets.saveEntry(setId, id: entryId, scoreId: 'scanned'));
      await tester.pump();

      expect(opened, [
        AppRoute.perform('scanned', setId: setId, entryId: entryId),
      ]);
    });
  });
}

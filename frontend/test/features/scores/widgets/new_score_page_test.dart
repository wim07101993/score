import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/scores/widgets/score_detail/details/upload_score_button.dart';
import 'package:score/router.dart';

import '../../../test_get_it.dart';

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

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: AppRouter().config(
          deepLinkBuilder: (_) => const DeepLink([NewScoreRoute()]),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UploadScoreButton), findsOneWidget);
    expect(find.text('Scores are for score viewers.'), findsNothing);
  });

  testWidgets('somebody who is not an editor is told uploading is not theirs', (
    tester,
  ) async {
    await tester.runAsync(
      () => GetIt.I.registerForTesting(
        user: const {
          'sub': 'player',
          'roles': {'score_viewer': <String, dynamic>{}},
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: AppRouter().config(
          deepLinkBuilder: (_) => const DeepLink([NewScoreRoute()]),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UploadScoreButton), findsNothing);
    expect(find.text('Uploading scores is for score editors.'), findsOneWidget);
  });
}

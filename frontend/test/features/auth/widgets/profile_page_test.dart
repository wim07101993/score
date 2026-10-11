import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/widgets/profile_page.dart';
import 'package:score/features/auth/widgets/refresh_token_button.dart';
import 'package:score/features/auth/widgets/sign_in_button.dart';

import '../../../test_get_it.dart';

void main() {
  tearDown(() => GetIt.I.popScope());

  testWidgets('shows who is signed in and what they may do', (tester) async {
    await tester.runAsync(
      () => GetIt.I.registerForTesting(
        user: const {
          'sub': 'player',
          'name': 'Ada Player',
          'email': 'ada@score.test',
          'roles': {'score_viewer': <String, dynamic>{}},
        },
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pump();

    expect(find.text('Ada Player'), findsOneWidget);
    expect(find.text('ada@score.test'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
    expect(find.text('See scores and sets'), findsOneWidget);
    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Not allowed'), findsOneWidget);
    expect(find.byType(SignInButton), findsNothing);
  });

  testWidgets('keeps the technical details folded away', (tester) async {
    await tester.runAsync(
      () => GetIt.I.registerForTesting(user: const {'sub': 'player'}),
    );

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pump();

    expect(find.text('Technical details'), findsOneWidget);
    expect(find.byType(RefreshTokenButton), findsNothing);
    expect(find.text('Client id'), findsNothing);

    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();

    expect(find.byType(RefreshTokenButton), findsOneWidget);
    expect(find.text('Client id'), findsOneWidget);
    expect(find.text('player'), findsOneWidget);
  });

  testWidgets('asks someone who is not signed in to sign in', (tester) async {
    await tester.runAsync(() => GetIt.I.registerForTesting());

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
    await tester.pump();

    expect(find.text('You are not signed in'), findsOneWidget);
    expect(find.byType(SignInButton), findsOneWidget);
    expect(find.text('What you can do'), findsNothing);
  });
}

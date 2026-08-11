import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/ui/starting.dart';
import 'package:score/ui/theme.dart';

/// The screen that is up while the app is still opening a database.
///
/// On a device it is a spinner and nothing more. In a browser it is a spinner
/// that has been handed an address — a link straight into a score, usually,
/// because that is what a player keeps in their bookmarks — and it has no such
/// page to show. Left to itself a navigator says so on the console every time
/// the app is restarted:
///
///     Could not navigate to initial route.
///
/// The app recovers a moment later, when the screen that does have those pages
/// replaces this one, which is what made it easy to leave alone.

Widget _starting({Object? failure}) => Starting(
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      failure: failure,
    );

void main() {
  /// The address the app was opened at, as the browser reports it.
  void openedAt(WidgetTester tester, String address) {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = address;
    addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
  }

  testWidgets('a link straight into a score is not something to complain about',
      (tester) async {
    // Every complaint this screen makes is a test failure here, which is the
    // point: the error being fixed was reported rather than thrown, so it cost
    // nothing but noise and could sit there for as long as nobody minded it.
    openedAt(tester, '/scores/abc?set=def&entry=ghi');

    await tester.pumpWidget(_starting());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('nor is a link to a set, or to any other page', (tester) async {
    for (final address in ['/sets/abc', '/settings', '/profile', '/nowhere']) {
      openedAt(tester, address);

      await tester.pumpWidget(_starting());
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('one screen, however deep the address', (tester) async {
    openedAt(tester, '/scores/abc?set=def&entry=ghi');

    await tester.pumpWidget(_starting());

    // Not one page per part of the address, which is the other way this can go
    // wrong: a stack of spinners with a back button between them.
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('an app that could not start says so instead of spinning',
      (tester) async {
    openedAt(tester, '/scores/abc');

    await tester.pumpWidget(_starting(failure: 'no database'));

    expect(find.text('The app could not start.'), findsOneWidget);
    expect(find.text('no database'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:score/ui/routes.dart';

/// Addresses, and what is behind them.
///
/// The addresses are the ones the app this replaces used, so a link a player
/// has in their browser still opens what it always opened. What is new is the
/// second question: a browser hands over a whole address at once, and this app
/// has to say what a player finds when they leave the page it opened.

void main() {
  group('reading an address', () {
    test('a score inside a set carries both, and which entry', () {
      final route = AppRoute.parse('/scores/abc?set=def&entry=ghi');

      expect(
        route,
        isA<ScoreDetailRoute>()
            .having((r) => r.scoreId, 'scoreId', 'abc')
            .having((r) => r.setId, 'setId', 'def')
            .having((r) => r.entryId, 'entryId', 'ghi'),
      );
    });

    test('anything unrecognised is the list of scores', () {
      expect(AppRoute.parse('/nowhere'), isA<ScoresRoute>());
      expect(AppRoute.parse(null), isA<ScoresRoute>());
      expect(AppRoute.parse('/'), isA<ScoresRoute>());
    });

    test('an address read and written again is the address it was', () {
      const addresses = [
        '/',
        '/sets',
        '/profile',
        '/settings',
        '/sets/abc',
        '/scores/abc',
        '/scores/abc?set=def&entry=ghi',
      ];

      for (final address in addresses) {
        expect(AppRoute.parse(address).path, address);
      }
    });
  });

  group('what a link opens onto', () {
    test('a score has the list of scores behind it, once', () {
      final stack = AppRoute.stackFor('/scores/abc');

      expect(stack, [isA<ScoresRoute>(), isA<ScoreDetailRoute>()]);
    });

    test("a set's score can be left through the set it is played from", () {
      final stack = AppRoute.stackFor('/sets/def');

      expect(stack, [isA<ScoresRoute>(), isA<SetsRoute>(), isA<SetDetailRoute>()]);
    });

    test('the list of scores is not put behind itself', () {
      expect(AppRoute.stackFor('/'), [isA<ScoresRoute>()]);
      expect(AppRoute.stackFor('/nowhere'), [isA<ScoresRoute>()]);
    });

    test('every address leads somewhere, and ends where it was pointed', () {
      const addresses = [
        '/',
        '/sets',
        '/sets/abc',
        '/scores/abc',
        '/scores/abc?set=def&entry=ghi',
        '/profile',
        '/settings',
      ];

      for (final address in addresses) {
        final stack = AppRoute.stackFor(address);
        expect(stack, isNotEmpty, reason: address);
        expect(stack.last.path, address, reason: address);
        // Nothing is opened twice: a way back that arrives where it started is
        // the thing this exists to prevent.
        expect(
          stack.map((route) => route.path).toSet().length,
          stack.length,
          reason: address,
        );
      }
    });
  });
}

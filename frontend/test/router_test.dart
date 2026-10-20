import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score/router.dart';

/// Addresses, and what is behind them.
///
/// A browser hands over a whole address at once, and this app has to say what
/// a player finds when they leave the page it opened.

final _router = AppRouter();

/// The pages [address] opens onto, by their address.
List<String> _pathsAt(String address) => [
  for (final route in _router.stackAt(address)) _router.pathOf(route),
];

/// The page [address] opens.
PageRouteInfo _at(String address) => _router.stackAt(address).last;

Matcher _route(
  String name, {
  Map<String, Object?> path = const {},
  Map<String, Object?> query = const {},
}) => isA<PageRouteInfo>()
    .having((r) => r.routeName, 'routeName', name)
    .having((r) => r.rawPathParams, 'path', path)
    .having((r) => r.rawQueryParams, 'query', query);

void main() {
  group('reading an address', () {
    test('a song of a set carries the set, and which of its songs', () {
      expect(
        _at('/sets/def/ghi'),
        _route(SetEntryRoute.name, path: {'setId': 'def', 'entryId': 'ghi'}),
      );
    });

    test('a piece of a collection carries the collection, and which piece', () {
      expect(
        _at('/collections/def/ghi'),
        _route(
          CollectionEntryRoute.name,
          path: {'collectionId': 'def', 'entryId': 'ghi'},
        ),
      );
    });

    test('anything unrecognised is the list of scores', () {
      expect(_at('/nowhere'), _route(ScoresRoute.name));
      expect(_at('/'), _route(ScoresRoute.name));
      expect(_at('/scores'), _route(ScoresRoute.name));
    });

    test('an address that cannot be read at all is the list of scores', () {
      // Escapes that are not UTF-8, and one with nothing after the scheme.
      expect(_at('/scores/%E9t%E9'), _route(ScoresRoute.name));
      expect(_at('/sets/abc?isPerforming=%FF'), _route(ScoresRoute.name));
      expect(_router.stackAt('//a:b/'), [_route(ScoresRoute.name)]);
    });

    test('a trailing slash is the same page', () {
      expect(_at('/sets/'), _route(SetsRoute.name));
      expect(_at('/collections/'), _route(CollectionsRoute.name));
    });

    test('a score is played from its own address', () {
      expect(
        _at('/scores/abc?isPerforming=true'),
        _route(
          ScoreDetailRoute.name,
          path: {'scoreId': 'abc'},
          query: {'isPerforming': 'true'},
        ),
      );
      expect(
        _at('/scores/abc'),
        _route(ScoreDetailRoute.name, path: {'scoreId': 'abc'}),
      );
    });

    test('an address read and written again is the address it was', () {
      const addresses = [
        '/scores',
        '/scores/abc',
        '/scores/abc?isPerforming=true',
        '/sets',
        '/sets/abc',
        '/sets/abc/def',
        '/sets/abc/def?isPerforming=true',
        '/collections',
        '/collections/abc',
        '/collections/abc/def',
        '/collections/abc/def?isPerforming=true',
        '/profile',
        '/settings',
        '/settings/logs',
      ];

      for (final address in addresses) {
        expect(_router.pathOf(_at(address)), address);
      }
    });

    test('a page that is not played says nothing about playing', () {
      expect(
        _router.pathOf(SetEntryRoute(setId: 'abc', entryId: 'def')),
        '/sets/abc/def',
      );
    });
  });

  group('what a link opens onto', () {
    test('a score has the list of scores behind it, once', () {
      expect(_pathsAt('/scores/abc'), ['/scores', '/scores/abc']);
    });

    test('a score played on its own has only the list of scores behind it', () {
      expect(_pathsAt('/scores/abc?isPerforming=true'), [
        '/scores',
        '/scores/abc?isPerforming=true',
      ]);
    });

    test('a set has the list of sets behind it', () {
      expect(_pathsAt('/sets/def'), ['/scores', '/sets', '/sets/def']);
    });

    test('a song of a set is left through that set', () {
      expect(_pathsAt('/sets/def/ghi?isPerforming=true'), [
        '/scores',
        '/sets',
        '/sets/def',
        '/sets/def/ghi?isPerforming=true',
      ]);
    });

    test('a piece of a collection is left through it', () {
      expect(_pathsAt('/collections/def/ghi'), [
        '/scores',
        '/collections',
        '/collections/def',
        '/collections/def/ghi',
      ]);
    });

    test('the list of scores is not put behind itself', () {
      expect(_pathsAt('/'), ['/scores']);
      expect(_pathsAt('/nowhere'), ['/scores']);
    });

    test('every address leads somewhere, and ends where it was pointed', () {
      const addresses = [
        '/scores',
        '/scores/abc',
        '/scores/abc?isPerforming=true',
        '/sets',
        '/sets/abc',
        '/sets/abc/def',
        '/sets/abc/def?isPerforming=true',
        '/collections',
        '/collections/abc',
        '/collections/abc/def',
        '/collections/abc/def?isPerforming=true',
        '/profile',
        '/settings',
      ];

      for (final address in addresses) {
        final stack = _pathsAt(address);
        expect(stack, isNotEmpty, reason: address);
        expect(stack.last, address, reason: address);
        // Nothing is opened twice: a way back that arrives where it started is
        // the thing this exists to prevent.
        expect(stack.toSet().length, stack.length, reason: address);
      }
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/scores/models/score_view_settings.dart';

/// What a collection is, written down and read back.
///
/// A collection is kept on this device between visits and handed to and from
/// the API as JSON, so whatever it says has to come back saying the same thing.

void main() {
  group('a piece of a collection', () {
    test('is called by the title of its score', () {
      const entry = CollectionEntry(id: 'e1', scoreId: 'score-1');

      expect(entry.nameWith((_) => 'Blue Bossa'), 'Blue Bossa');
      expect(entry.nameWith((_) => null), 'Not on this device yet');
    });

    test('kept on this device from before it needed a score is left out', () {
      final back = Collection.fromJson({
        'id': 'c1',
        'entries': [
          {'id': 'e1', 'score_id': 'score-1'},
          {'id': 'e2', 'score_id': null, 'description': 'page 62'},
          {'id': 'e3', 'score_id': 'null', 'description': 'page 64'},
        ],
      });

      expect(back.entries.map((entry) => entry.id), ['e1']);
    });
  });

  group('a collection kept on this device', () {
    test('comes back as it was', () {
      final collection = Collection(
        id: 'c1',
        title: 'The Real Book, vol. 1',
        description: 'what the band can be asked for',
        entries: [
          CollectionEntry(
            id: 'e1',
            scoreId: 'score-1',
            description: 'the arrangement we do',
            transposition: -2,
            view: ScoreViewSettings(
              transposition: 5,
              hiddenParts: const ['P2'],
              zoom: 1.5,
            ),
          ),
        ],
        sharedWith: const ['bas@example.com'],
        isOwner: true,
        lastChangedAt: DateTime.utc(2026, 9, 1, 12),
      );

      final stored = jsonDecode(jsonEncode(collection.toJson()));
      final back = Collection.fromJson(
        (stored as Map).cast<String, Object?>(),
      );

      expect(back.title, 'The Real Book, vol. 1');
      expect(back.description, 'what the band can be asked for');
      expect(back.sharedWith, ['bas@example.com']);
      expect(back.lastChangedAt, DateTime.utc(2026, 9, 1, 12));
      final scanned = back.entries.first;
      expect(scanned.scoreId, 'score-1');
      expect(scanned.transposition, -2);
      expect(scanned.view.transposition, 5);
      expect(scanned.view.hiddenParts, ['P2']);
      expect(scanned.view.zoom, 1.5);
    });
  });

  group('how big a player draws a piece', () {
    ScoreViewSettings zoomedTo(double zoom) => ScoreViewSettings(
      transposition: 0,
      hiddenParts: const [],
      zoom: zoom,
    );

    test('is held to what the API takes', () {
      expect(zoomedTo(0.1).zoom, ScoreViewSettings.minZoom);
      expect(zoomedTo(10).zoom, ScoreViewSettings.maxZoom);
      expect(zoomedTo(1.5).zoom, 1.5);
    });

    test('is read back when it is a whole number', () {
      expect(ScoreViewSettings.fromJson({'zoom': 2}).zoom, 2);
    });

    test('is the size it is written at when nothing sensible was said', () {
      expect(ScoreViewSettings.fromJson({'zoom': null}).zoom, 1);
      expect(ScoreViewSettings.fromJson({'zoom': 'big'}).zoom, 1);
    });
  });

  group('the order a collection is read in', () {
    String? titleOf(String scoreId) => const {
      'a': 'Autumn Leaves',
      'b': 'Blue Monk',
      'c': 'Anthropology',
      'd': 'bebop',
      'e': 'Autumn',
      'x': 'page 12',
      'y': 'page 12',
    }[scoreId];

    test('is by the title of each piece', () {
      const entries = [
        CollectionEntry(id: '1', scoreId: 'b'),
        CollectionEntry(id: '2', scoreId: 'c'),
        CollectionEntry(id: '3', scoreId: 'a'),
      ];

      final byTitle = CollectionEntry.sortByTitle(entries, titleOf);

      expect([for (final entry in byTitle) entry.id], ['2', '3', '1']);
    });

    test('does not care about case', () {
      const entries = [
        CollectionEntry(id: '1', scoreId: 'd'),
        CollectionEntry(id: '2', scoreId: 'e'),
      ];

      final byTitle = CollectionEntry.sortByTitle(entries, titleOf);

      expect([for (final entry in byTitle) entry.id], ['2', '1']);
    });

    test('keeps two pieces with the same name in the same order', () {
      const entries = [
        CollectionEntry(id: 'z', scoreId: 'x'),
        CollectionEntry(id: 'y', scoreId: 'y'),
      ];

      expect(
        [
          for (final entry in CollectionEntry.sortByTitle(entries, titleOf))
            entry.id,
        ],
        ['y', 'z'],
      );
      expect(
        [
          for (final entry in CollectionEntry.sortByTitle(
            entries.reversed,
            titleOf,
          ))
            entry.id,
        ],
        ['y', 'z'],
      );
    });
  });

  test('what the group plays and what the player reads are added together', () {
    final entry = CollectionEntry(
      id: 'e1',
      scoreId: 'score-1',
      transposition: 10,
      view: ScoreViewSettings(
        transposition: 10,
        hiddenParts: const [],
        zoom: 1,
      ),
    );

    expect(entry.combinedTransposition, 12, reason: 'as far as it goes');
  });
}

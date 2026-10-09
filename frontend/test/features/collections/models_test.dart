import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/collections/models.dart';

/// What a collection is, written down and read back.
///
/// A collection is kept on this device between visits and handed to and from
/// the API as JSON, so whatever it says has to come back saying the same thing
/// — above all what is *not* there. A piece that has yet to be scanned has no
/// score, and an entry that forgets that on the way through turns into a piece
/// named after a score called `null`, which the server refuses and the player
/// can never open.

void main() {
  group('a piece that has yet to be scanned', () {
    test('still has none after being kept on this device and read back', () {
      const entry = CollectionEntry(id: 'e1', description: 'page 62');

      // Through the text it is actually stored as, rather than the map, so
      // that a null which turned into a string on the way would be caught.
      final stored = jsonDecode(jsonEncode(entry.toJson()));
      final back = CollectionEntry.fromJson(
        (stored as Map).cast<String, Object?>(),
      );

      expect(entry.toJson()['score_id'], isNull);
      expect(
        entry.toJson().containsKey('score_id'),
        isTrue,
        reason: 'said to be nothing, rather than not said at all',
      );
      expect(back.scoreId, isNull);
      expect(back.scoreId, isNot('null'));
    });

    test('that was once written down as the text null is read as none', () {
      // It is what a null turns into when it is written out as text, and read
      // back as an id it would be sent to the server as a score that does not
      // exist.
      final entry = CollectionEntry.fromJson(
        {'id': 'e1', 'score_id': 'null'},
      );

      expect(entry.scoreId, isNull);
    });

    test('that was typed as nothing is a piece with no score', () {
      // A form hands over what was typed into it, and what nobody typed a score
      // into is a piece that is in the collection but not in here.
      expect(scoreIdOf('   '), isNull);
      expect(scoreIdOf(''), isNull);
      expect(scoreIdOf(' abc '), 'abc');
    });

    test('is called by what is written next to it', () {
      const entry = CollectionEntry(id: 'e1', description: ' page 62 ');

      expect(entry.nameWith((_) => 'never asked'), 'page 62');
    });
  });

  group('a collection kept on this device', () {
    test('comes back as it was, with everything it still owes', () {
      final collection = Collection(
        id: 'c1',
        title: 'The Real Book, vol. 1',
        description: 'what the band can be asked for',
        entries: const [
          CollectionEntry(
            id: 'e1',
            scoreId: 'score-1',
            description: 'the arrangement we do',
            transposition: -2,
            view: CollectionEntryView(
              transposition: 5,
              hiddenParts: ['P2'],
              zoom: 1.5,
            ),
            synced: true,
          ),
          CollectionEntry(id: 'e2', description: 'page 62'),
        ],
        sharedWith: const ['bas@example.com'],
        lastChangedAt: DateTime.utc(2026, 9, 1, 12),
        lastSyncedAt: DateTime.utc(2026, 9, 1, 11),
        pendingChange: PendingChange.write,
        pendingViews: const ['e1'],
        pendingEntries: const [
          PendingEntry(id: 'e2', action: PendingChange.write),
        ],
      );

      final stored = jsonDecode(jsonEncode(collection.toJson()));
      final back = Collection.fromJson(
        (stored as Map).cast<String, Object?>(),
      );

      expect(back.title, 'The Real Book, vol. 1');
      expect(back.description, 'what the band can be asked for');
      expect(back.sharedWith, ['bas@example.com']);
      expect(back.lastChangedAt, DateTime.utc(2026, 9, 1, 12));
      expect(back.lastSyncedAt, DateTime.utc(2026, 9, 1, 11));
      expect(back.deletedAt, isNull);
      expect(back.pendingChange, PendingChange.write);
      expect(back.pendingViews, ['e1']);
      expect(back.pendingEntries.single.id, 'e2');
      expect(back.pendingEntries.single.action, PendingChange.write);

      final scanned = back.entries.first;
      expect(scanned.scoreId, 'score-1');
      expect(scanned.transposition, -2);
      expect(scanned.view.transposition, 5);
      expect(scanned.view.hiddenParts, ['P2']);
      expect(scanned.view.zoom, 1.5);
      expect(scanned.synced, isTrue);

      final onPaper = back.entries.last;
      expect(onPaper.scoreId, isNull);
      expect(onPaper.synced, isFalse);
    });

    test('that owes nothing and was never deleted says so', () {
      final collection = Collection(
        id: 'c1',
        lastChangedAt: DateTime.utc(2026),
      );

      final back = Collection.fromJson(collection.toJson());

      expect(back.pendingChange, isNull);
      expect(back.deletedAt, isNull);
      expect(back.lastSyncedAt, isNull);
      expect(back.owesAnything, isFalse);
    });
  });

  group('how big a player draws a piece', () {
    test('is held to what the API takes', () {
      expect(zoomOf(0.1), minZoom);
      expect(zoomOf(10), maxZoom);
      expect(zoomOf(1.5), 1.5);
    });

    test('is the size it is written at when nothing sensible was said', () {
      expect(zoomOf(null), 1);
      expect(zoomOf('big'), 1);
      expect(zoomOf(double.nan), 1);
    });
  });

  group('the order a collection is read in', () {
    String? titleOf(String scoreId) =>
        const {'a': 'Autumn Leaves', 'b': 'Blue Monk'}[scoreId];

    test('is by what each piece is called, wherever that comes from', () {
      const entries = [
        CollectionEntry(id: '1', scoreId: 'b'),
        CollectionEntry(id: '2', description: 'Anthropology — page 20'),
        CollectionEntry(id: '3', scoreId: 'a'),
      ];

      final byTitle = entriesByTitle(entries, titleOf);

      expect([for (final entry in byTitle) entry.id], ['2', '3', '1']);
    });

    test('does not care about case', () {
      const entries = [
        CollectionEntry(id: '1', description: 'bebop'),
        CollectionEntry(id: '2', description: 'Autumn'),
      ];

      final byTitle = entriesByTitle(entries, titleOf);

      expect([for (final entry in byTitle) entry.id], ['2', '1']);
    });

    test('keeps two pieces with the same name in the same order', () {
      const entries = [
        CollectionEntry(id: 'z', description: 'page 12'),
        CollectionEntry(id: 'y', description: 'page 12'),
      ];

      expect(
        [for (final entry in entriesByTitle(entries, titleOf)) entry.id],
        ['y', 'z'],
      );
      expect(
        [
          for (final entry in entriesByTitle(entries.reversed, titleOf))
            entry.id,
        ],
        ['y', 'z'],
      );
    });
  });

  test('what the group plays and what the player reads are added together', () {
    const entry = CollectionEntry(
      id: 'e1',
      scoreId: 'score-1',
      transposition: 10,
      view: CollectionEntryView(transposition: 10),
    );

    expect(entry.readAt, 12, reason: 'as far as it goes');
  });
}

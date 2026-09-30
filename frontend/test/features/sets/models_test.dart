import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/sets/models.dart';

/// A song in a set that the band plays from paper has no score, and stays that
/// way however often it is read, stored and read again.

void main() {
  group('a song with no score', () {
    test('is read from the API as having none', () {
      final entry = SetEntry.fromApi({'id': 'a', 'score_id': null});

      expect(entry.scoreId, isNull);
    });

    test('is stored and read back as having none', () {
      final entry = SetEntry.fromJson(
        SetEntry.fromApi({'id': 'a', 'score_id': null}).toJson(),
      );

      expect(entry.scoreId, isNull);
      expect(entry.toJson(), containsPair('score_id', null));
    });

    test('stored by an earlier version as the text null has none', () {
      expect(SetEntry.fromJson({'id': 'a', 'score_id': 'null'}).scoreId, isNull);
      expect(SetEntry.fromJson({'id': 'a', 'score_id': ''}).scoreId, isNull);
    });
  });

  test('a song with a score keeps it', () {
    final entry = SetEntry.fromJson(
      SetEntry.fromApi({'id': 'a', 'score_id': 'score-1'}).toJson(),
    );

    expect(entry.scoreId, 'score-1');
  });

  test('a moment is written down as one, whatever zone reads it back', () {
    // Written as this device's local time it would carry no offset, and be
    // read back in whatever zone the device is in by then.
    final at = DateTime(2026, 6, 1, 20);
    final set = ScoreSet(id: 's', lastChangedAt: at, lastSyncedAt: at);

    final json = set.toJson();
    final back = ScoreSet.fromJson(json);

    expect(json['last_synced_at'], endsWith('Z'));
    expect(json['last_changed_at'], endsWith('Z'));
    expect(back.lastSyncedAt!.isAtSameMomentAs(at), isTrue);
    expect(back.lastChangedAt.isAtSameMomentAs(at), isTrue);
  });

  test('how big a player draws a song is part of how they read it', () {
    final view = EntryView.fromJson(
      {'transposition': 2, 'hidden_parts': ['P2'], 'zoom': 2.5},
    );

    expect(view.zoom, 2.5);
    expect(view.toJson(), containsPair('zoom', 2.5));
    expect(EntryView.fromJson({'transposition': 0}).zoom, 1,
        reason: 'a view that says nothing about its size is the written size');
  });
}

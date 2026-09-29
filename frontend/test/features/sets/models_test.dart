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
}

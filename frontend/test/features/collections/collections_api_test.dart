import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:score/config.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/storage/clients.dart';

/// What the collections client makes of a collection the server hands over —
/// above all what is *not* there. A piece that has yet to be scanned has no
/// score, and an entry that forgets that on the way in turns into a piece
/// named after a score called `null`, which the server refuses and the player
/// can never open.
void main() {
  CollectionsApi answering(Object body) => CollectionsApi(
    clientFactory: ApiClientFactory(
      config: ApiConfig(baseUrl: Uri.parse('https://api.test/')),
      inner: MockClient(
        (_) async => http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      authToken: () async => 'a-token',
    ),
  );

  test('a piece that has yet to be scanned has no score', () async {
    final api = answering({
      ..._collection,
      'entries': [_entry(scoreId: null, description: 'Blue Bossa — page 62')],
    });

    final entry = (await api.getCollection('c1'))!.entries.single;
    expect(entry.scoreId, isNull);
    expect(entry.isOnPaper, isTrue);
  });

  test('a collection handed over owes nothing', () async {
    final api = answering({
      ..._collection,
      'entries': [_entry(scoreId: 'score-1', description: '')],
    });

    final collection = (await api.getCollection('c1'))!;
    expect(collection.isOwner, isFalse);
    expect(collection.owesAnything, isFalse);
    expect(
      collection.entries.single.synced,
      isTrue,
      reason: 'everything the API hands over is on the server',
    );
  });

  test('a collection deleted there says when', () async {
    final api = answering([
      {..._collection, 'deleted_at': '2026-09-01T00:00:00Z'},
    ]);

    expect(
      (await api.listCollections(null, null)).single.deletedAt,
      DateTime.utc(2026, 9),
    );
  });
}

final _collection = {
  'id': 'c1',
  'title': 'The Real Book',
  'description': '',
  'entries': <Object>[],
  'shared_with': <String>[],
  'is_owner': false,
  'last_changed_at': '2026-09-01T00:00:00Z',
  'deleted_at': null,
};

Map<String, Object?> _entry({
  required String? scoreId,
  required String description,
}) => {
  'id': 'e1',
  'score_id': scoreId,
  'description': description,
  'transposition': 0,
  'view': {'transposition': 0, 'hidden_parts': <String>[], 'zoom': 1},
};

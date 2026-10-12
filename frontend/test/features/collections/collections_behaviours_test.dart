import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:score/features/collections/behaviours/delete_collection.dart';
import 'package:score/features/collections/behaviours/delete_collection_entry.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/behaviours/save_collection.dart';
import 'package:score/features/collections/behaviours/save_collection_entry.dart';
import 'package:score/features/collections/behaviours/save_collection_entry_view.dart';
import 'package:score/features/collections/behaviours/sync_collections.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/storage/api_exception.dart';

import '../../test_api.dart';
import '../../test_stores.dart';

class _Api() extends CollectionsApi {
  this : super(clientFactory: testClientFactory());

  bool reachable = true;
  bool writesFail = false;
  final Map<String, Collection> collections = {};
  final List<Map<String, Object?>> entryWrites = [];
  final List<Map<String, Object?>> viewWrites = [];

  Collection _collection(String collectionId) =>
      collections[collectionId] ??
      (throw StateError('no collection $collectionId on the server'));

  void _failIfAsked() {
    if (writesFail) {
      throw ApiException(
        message: 'nothing answered',
        statusCode: null,
        problem: null,
      );
    }
  }

  @override
  Future<bool> canBeReached() async => reachable;

  @override
  Future<List<Collection>> listChanges({
    required DateTime since,
    DateTime? until,
  }) async => collections.values.toList(growable: false);

  @override
  Future<Collection?> getCollection(String collectionId) async =>
      collections[collectionId];

  @override
  Future<Collection> putCollection(
    String collectionId,
    Map<String, Object?> writeCollection,
  ) async {
    _failIfAsked();
    final existing = collections[collectionId];
    return collections[collectionId] = Collection(
      id: collectionId,
      title: writeCollection['title']! as String,
      description: writeCollection['description']! as String,
      entries: existing?.entries ?? const [],
      sharedWith: (writeCollection['shared_with']! as List).cast<String>(),
      isOwner: true,
      lastChangedAt: DateTime.utc(2026, 10),
      deletedAt: null,
    );
  }

  @override
  Future<CollectionEntry> putEntry(
    String collectionId,
    String entryId,
    Map<String, Object?> writeEntry,
  ) async {
    _failIfAsked();
    entryWrites.add(writeEntry);
    final collection = _collection(collectionId);
    final known = collection.entries
        .where((entry) => entry.id == entryId)
        .firstOrNull;
    final entry = CollectionEntry(
      id: entryId,
      scoreId: writeEntry['score_id'] as String?,
      description: writeEntry['description']! as String,
      transposition: writeEntry['transposition']! as int,
      view: known?.view ?? const ScoreViewSettings.defaultView(),
    );
    collections[collectionId] = collection.copyWith(
      entries: [
        ...collection.entries.where((entry) => entry.id != entryId),
        entry,
      ],
    );
    return entry;
  }

  @override
  Future<void> deleteEntry(String collectionId, String entryId) async {
    _failIfAsked();
    final collection = _collection(collectionId);
    collections[collectionId] = collection.copyWith(
      entries: collection.entries
          .where((entry) => entry.id != entryId)
          .toList(growable: false),
    );
  }

  @override
  Future<ScoreViewSettings> putEntryView(
    String collectionId,
    String entryId,
    Map<String, Object?> writeView,
  ) async {
    _failIfAsked();
    viewWrites.add(writeView);
    return ScoreViewSettings.fromJson(writeView);
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    _failIfAsked();
    collections.remove(collectionId);
  }
}

class _Collections({
  required final Stores store,
  required final _Api api,
}) {
  late final _fetch = FetchCollection(api: api, db: store.collections);

  Future<void> sync() => SyncCollections(
    logger: Logger('test'),
    db: store.collections,
    api: api,
    syncDates: store.syncDates,
  ).action(null);

  Future<Collection?> getCollection(String collectionId) => GetCollection(
    db: store.collections,
    api: api,
    fetch: _fetch,
  ).action(collectionId, null);

  Future<Collection> saveCollection(SaveCollectionParams params) =>
      SaveCollection(api: api, db: store.collections).action(params, null);

  Future<Collection> saveEntry(SaveCollectionEntryParams params) =>
      SaveCollectionEntry(
        api: api,
        db: store.collections,
        fetch: _fetch,
      ).action(params, null);

  Future<Collection> deleteEntry(String collectionId, String entryId) =>
      DeleteCollectionEntry(api: api, fetch: _fetch).action(
        DeleteCollectionEntryParams(
          collectionId: collectionId,
          entryId: entryId,
        ),
        null,
      );

  Future<Collection> saveView(SaveCollectionEntryViewParams params) =>
      SaveCollectionEntryView(
        api: api,
        db: store.collections,
        fetch: _fetch,
      ).action(params, null);

  Future<void> deleteCollection(String collectionId) => DeleteCollection(
    api: api,
    db: store.collections,
  ).action(collectionId, null);
}

void main() {
  late Stores store;
  late _Api api;
  late _Collections collections;

  setUp(() async {
    store = await Stores.inMemory();
    api = _Api();
    collections = _Collections(store: store, api: api);
  });

  group('saving a collection', () {
    test('writes it to the server and keeps the answer', () async {
      await collections.saveCollection(
        const SaveCollectionParams(id: 'book', title: 'The Real Book'),
      );

      expect(api.collections['book']!.title, 'The Real Book');
      expect((await store.collections.get('book'))!.title, 'The Real Book');
    });

    test('keeps nothing when the server does not take it', () async {
      api.writesFail = true;

      await expectLater(
        collections.saveCollection(
          const SaveCollectionParams(id: 'book', title: 'The Real Book'),
        ),
        throwsA(isA<ApiException>()),
      );
      expect(await store.collections.get('book'), isNull);
    });
  });

  group('a piece of a collection', () {
    setUp(() async {
      await collections.saveCollection(
        const SaveCollectionParams(id: 'book', title: 'The Real Book'),
      );
    });

    test('is written to the server and read back', () async {
      final collection = await collections.saveEntry(
        const SaveCollectionEntryParams(
          collectionId: 'book',
          id: 'e1',
          scoreId: 'score-1',
          transposition: -2,
        ),
      );

      expect(collection.entries.single.scoreId, 'score-1');
      expect(api.entryWrites.single, {
        'score_id': 'score-1',
        'description': '',
        'transposition': -2,
      });
      expect(
        (await store.collections.get('book'))!.entries.single.id,
        'e1',
      );
    });

    test('is not put in twice', () async {
      await collections.saveEntry(
        const SaveCollectionEntryParams(
          collectionId: 'book',
          id: 'e1',
          scoreId: 'score-1',
        ),
      );

      await expectLater(
        collections.saveEntry(
          const SaveCollectionEntryParams(
            collectionId: 'book',
            scoreId: 'score-1',
          ),
        ),
        throwsA(
          isA<ScoreAlreadyInCollectionException>().having(
            (error) => error.entryId,
            'entryId',
            'e1',
          ),
        ),
      );
      expect(api.entryWrites, hasLength(1));
    });

    test('with no score needs a name', () async {
      await expectLater(
        collections.saveEntry(
          const SaveCollectionEntryParams(collectionId: 'book', onPaper: true),
        ),
        throwsA(isA<UnnamedPieceException>()),
      );
      expect(api.entryWrites, isEmpty);
    });

    test('is taken out on the server and here', () async {
      await collections.saveEntry(
        const SaveCollectionEntryParams(
          collectionId: 'book',
          id: 'e1',
          scoreId: 'score-1',
        ),
      );

      final collection = await collections.deleteEntry('book', 'e1');

      expect(collection.entries, isEmpty);
      expect((await store.collections.get('book'))!.entries, isEmpty);
    });

    test('is read the way this player says', () async {
      await collections.saveEntry(
        const SaveCollectionEntryParams(
          collectionId: 'book',
          id: 'e1',
          scoreId: 'score-1',
        ),
      );

      final collection = await collections.saveView(
        const SaveCollectionEntryViewParams(
          collectionId: 'book',
          entryId: 'e1',
          zoom: 1.5,
        ),
      );

      expect(api.viewWrites.single, {
        'transposition': 0,
        'hidden_parts': <String>[],
        'zoom': 1.5,
      });
      expect(collection.entries.single.view.zoom, 1.5);
      expect(
        (await store.collections.get('book'))!.entries.single.view.zoom,
        1.5,
      );
    });
  });

  group('deleting a collection', () {
    test('takes it off the server and off this device', () async {
      await collections.saveCollection(
        const SaveCollectionParams(id: 'book', title: 'The Real Book'),
      );

      await collections.deleteCollection('book');

      expect(api.collections, isEmpty);
      expect(await store.collections.get('book'), isNull);
    });
  });

  group('getting a collection', () {
    test('asks the server for one this device does not have', () async {
      await collections.saveCollection(
        const SaveCollectionParams(id: 'book', title: 'The Real Book'),
      );
      await store.collections.remove('book');

      final collection = await collections.getCollection('book');

      expect(collection?.title, 'The Real Book');
      expect(await store.collections.get('book'), isNotNull);
    });

    test('is nothing when the server cannot be reached', () async {
      api.reachable = false;

      expect(await collections.getCollection('book'), isNull);
    });
  });

  group('a sync', () {
    test('keeps what changed on the server', () async {
      api.collections['book'] = Collection(
        id: 'book',
        title: 'The Real Book',
        description: '',
        entries: const [],
        sharedWith: const [],
        isOwner: false,
        lastChangedAt: DateTime.utc(2026, 9),
        deletedAt: null,
      );

      await collections.sync();

      expect((await store.collections.get('book'))!.isOwner, isFalse);
      expect(
        await store.syncDates.lastSyncedAt(SyncCollections.key),
        DateTime.utc(2026, 9),
      );
    });
  });
}

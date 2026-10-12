import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/behaviours/delete_set.dart';
import 'package:score/features/sets/behaviours/delete_set_entry.dart';
import 'package:score/features/sets/behaviours/get_set.dart';
import 'package:score/features/sets/behaviours/save_set.dart';
import 'package:score/features/sets/behaviours/save_set_entry.dart';
import 'package:score/features/sets/behaviours/save_set_entry_view.dart';
import 'package:score/features/sets/behaviours/sync_sets.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sync/models.dart';
import 'package:score/storage/api_exception.dart';

import '../../test_api.dart';
import '../../test_stores.dart';

class _Api() extends SetsApi {
  this : super(clientFactory: testClientFactory());

  bool reachable = true;
  bool writesFail = false;
  final Map<String, ScoreSet> sets = {};
  final Map<String, DateTime> deleted = {};
  final List<Map<String, Object?>> entryWrites = [];
  final List<Map<String, Object?>> viewWrites = [];
  final List<DateTime> since = [];

  ScoreSet _set(String setId) =>
      sets[setId] ?? (throw StateError('no set $setId on the server'));

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
  Future<SyncChanges<ScoreSet>> listChanges({
    required DateTime since,
    DateTime? until,
  }) async {
    this.since.add(since);
    return (
      changed: sets.values.toList(growable: false),
      deleted: deleted.entries
          .map((gone) => DeletedEntity(id: gone.key, deletedAt: gone.value))
          .toList(growable: false),
    );
  }

  @override
  Future<ScoreSet?> getSet(String setId) async => sets[setId];

  @override
  Future<ScoreSet> putSet(String setId, Map<String, Object?> writeSet) async {
    _failIfAsked();
    final existing = sets[setId];
    return sets[setId] = ScoreSet(
      id: setId,
      title: writeSet['title']! as String,
      description: writeSet['description']! as String,
      entries: existing?.entries ?? const [],
      sharedWith: (writeSet['shared_with']! as List).cast<String>(),
      isOwner: true,
      lastChangedAt: DateTime.utc(2026, 10),
    );
  }

  @override
  Future<({SetEntry entry, int? position})> putEntry(
    String setId,
    String entryId,
    Map<String, Object?> writeEntry,
  ) async {
    _failIfAsked();
    entryWrites.add(writeEntry);
    final set = _set(setId);
    final known = set.entries.where((entry) => entry.id == entryId).firstOrNull;
    final entry = SetEntry(
      id: entryId,
      scoreId: writeEntry['score_id'] as String?,
      description: writeEntry['description']! as String,
      transposition: writeEntry['transposition']! as int,
      view: known?.view ?? const ScoreViewSettings.defaultView(),
    );
    final others = set.entries.where((entry) => entry.id != entryId).toList();
    final position = (writeEntry['position']! as int).clamp(0, others.length);
    sets[setId] = set.copyWith(
      entries: [
        ...others.sublist(0, position),
        entry,
        ...others.sublist(position),
      ],
    );
    return (entry: entry, position: position);
  }

  @override
  Future<void> deleteEntry(String setId, String entryId) async {
    _failIfAsked();
    final set = _set(setId);
    sets[setId] = set.copyWith(
      entries: set.entries
          .where((entry) => entry.id != entryId)
          .toList(growable: false),
    );
  }

  @override
  Future<ScoreViewSettings> putEntryView(
    String setId,
    String entryId,
    Map<String, Object?> writeView,
  ) async {
    _failIfAsked();
    viewWrites.add(writeView);
    return ScoreViewSettings.fromJson(writeView);
  }

  @override
  Future<void> deleteSet(String setId) async {
    _failIfAsked();
    sets.remove(setId);
    deleted[setId] = DateTime.utc(2026, 11);
  }
}

class _Sets({
  required final Stores store,
  required final _Api api,
}) {
  late final _fetch = FetchSet(api: api, db: store.sets);

  Future<void> sync() => SyncSets(
    logger: Logger('test'),
    db: store.sets,
    api: api,
    syncDates: store.syncDates,
  ).action(null);

  Future<ScoreSet?> getSet(String setId) =>
      GetSet(db: store.sets, api: api, fetch: _fetch).action(setId, null);

  Future<ScoreSet> saveSet(SaveSetParams params) =>
      SaveSet(api: api, db: store.sets).action(params, null);

  Future<ScoreSet> saveEntry(SaveSetEntryParams params) => SaveSetEntry(
    api: api,
    db: store.sets,
    fetch: _fetch,
  ).action(params, null);

  Future<ScoreSet> deleteEntry(String setId, String entryId) => DeleteSetEntry(
    api: api,
    fetch: _fetch,
  ).action(DeleteSetEntryParams(setId: setId, entryId: entryId), null);

  Future<ScoreSet> saveView(SaveSetEntryViewParams params) => SaveSetEntryView(
    api: api,
    db: store.sets,
    fetch: _fetch,
  ).action(params, null);

  Future<void> deleteSet(String setId) =>
      DeleteSet(api: api, db: store.sets).action(setId, null);
}

void main() {
  late Stores store;
  late _Api api;
  late _Sets sets;

  setUp(() async {
    store = await Stores.inMemory();
    api = _Api();
    sets = _Sets(store: store, api: api);
  });

  group('saving a set', () {
    test('writes it to the server and keeps the answer', () async {
      final saved = await sets.saveSet(
        const SaveSetParams(
          id: 'gig',
          title: 'Friday',
          sharedWith: [' Bas@Example.com', 'bas@example.com'],
        ),
      );

      expect(api.sets['gig']!.title, 'Friday');
      expect(saved.sharedWith, ['bas@example.com']);
      expect((await store.sets.get('gig'))!.title, 'Friday');
    });

    test('keeps nothing when the server does not take it', () async {
      api.writesFail = true;

      await expectLater(
        sets.saveSet(const SaveSetParams(id: 'gig', title: 'Friday')),
        throwsA(isA<ApiException>()),
      );
      expect(await store.sets.get('gig'), isNull);
    });
  });

  group('a song of a set', () {
    setUp(() async {
      await sets.saveSet(const SaveSetParams(id: 'gig', title: 'Friday'));
    });

    test('goes on the end when no place is said', () async {
      await sets.saveEntry(
        const SaveSetEntryParams(setId: 'gig', id: 'a', scoreId: 'score-a'),
      );
      final set = await sets.saveEntry(
        const SaveSetEntryParams(setId: 'gig', id: 'b', scoreId: 'score-b'),
      );

      expect(set.entries.map((entry) => entry.id), ['a', 'b']);
      expect(api.entryWrites.last['position'], 1);
      expect(
        (await store.sets.get('gig'))!.entries.map((entry) => entry.id),
        ['a', 'b'],
      );
    });

    test('stays where it is when only its note changes', () async {
      for (final id in ['a', 'b', 'c']) {
        await sets.saveEntry(
          SaveSetEntryParams(setId: 'gig', id: id, scoreId: 'score-$id'),
        );
      }

      final set = await sets.saveEntry(
        const SaveSetEntryParams(setId: 'gig', id: 'a', description: 'slow'),
      );

      expect(set.entries.map((entry) => entry.id), ['a', 'b', 'c']);
      expect(api.entryWrites.last, {
        'score_id': 'score-a',
        'description': 'slow',
        'transposition': 0,
        'position': 0,
      });
    });

    test('moves to the place it is written at', () async {
      for (final id in ['a', 'b', 'c']) {
        await sets.saveEntry(
          SaveSetEntryParams(setId: 'gig', id: id, scoreId: 'score-$id'),
        );
      }

      final set = await sets.saveEntry(
        const SaveSetEntryParams(setId: 'gig', id: 'c', position: 0),
      );

      expect(set.entries.map((entry) => entry.id), ['c', 'a', 'b']);
    });

    test('is taken out on the server and here', () async {
      await sets.saveEntry(
        const SaveSetEntryParams(setId: 'gig', id: 'a', scoreId: 'score-a'),
      );

      final set = await sets.deleteEntry('gig', 'a');

      expect(set.entries, isEmpty);
      expect((await store.sets.get('gig'))!.entries, isEmpty);
    });
  });

  group('how a song is read', () {
    setUp(() async {
      await sets.saveSet(const SaveSetParams(id: 'gig', title: 'Friday'));
      await sets.saveEntry(
        const SaveSetEntryParams(setId: 'gig', id: 'a', scoreId: 'score-a'),
      );
      await sets.saveView(
        const SaveSetEntryViewParams(
          setId: 'gig',
          entryId: 'a',
          hiddenParts: ['P2'],
          zoom: 2,
        ),
      );
    });

    test('is written whole, with what is not said kept as it is', () async {
      final set = await sets.saveView(
        const SaveSetEntryViewParams(
          setId: 'gig',
          entryId: 'a',
          transposition: 3,
        ),
      );

      expect(api.viewWrites.last, {
        'transposition': 3,
        'hidden_parts': ['P2'],
        'zoom': 2.0,
      });
      expect(set.entries.single.view.transposition, 3);
      expect(set.entries.single.view.hiddenParts, ['P2']);
      expect(
        (await store.sets.get('gig'))!.entries.single.view.transposition,
        3,
      );
    });
  });

  group('deleting a set', () {
    test('takes it off the server and off this device', () async {
      await sets.saveSet(const SaveSetParams(id: 'gig', title: 'Friday'));

      await sets.deleteSet('gig');

      expect(api.sets, isEmpty);
      expect(await store.sets.get('gig'), isNull);
    });
  });

  group('getting a set', () {
    test('asks the server for one this device does not have', () async {
      await sets.saveSet(const SaveSetParams(id: 'gig', title: 'Friday'));
      await store.sets.remove('gig');

      final set = await sets.getSet('gig');

      expect(set?.title, 'Friday');
      expect(await store.sets.get('gig'), isNotNull);
    });

    test('is nothing when the server cannot be reached', () async {
      api.reachable = false;

      expect(await sets.getSet('gig'), isNull);
    });
  });

  group('a sync', () {
    test('keeps what changed on the server', () async {
      api.sets['gig'] = ScoreSet(
        id: 'gig',
        title: 'Friday',
        description: '',
        entries: const [],
        sharedWith: const [],
        isOwner: false,
        lastChangedAt: DateTime.utc(2026, 9),
      );

      await sets.sync();

      expect((await store.sets.get('gig'))!.isOwner, isFalse);
      expect(
        await store.syncDates.lastSyncedAt(SyncSets.key),
        DateTime.utc(2026, 9),
      );
    });

    test('forgets what was deleted on the server', () async {
      await sets.saveSet(const SaveSetParams(id: 'gig', title: 'Friday'));
      api.sets.remove('gig');
      api.deleted['gig'] = DateTime.utc(2026, 11);

      await sets.sync();

      expect(await store.sets.get('gig'), isNull);
      expect(
        await store.syncDates.lastSyncedAt(SyncSets.key),
        DateTime.utc(2026, 11),
      );
    });
  });
}

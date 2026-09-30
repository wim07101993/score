import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/repository.dart';

/// What a set does when the server is not there.
///
/// This is the part of the app that has to be right on a stage: a set is edited
/// where there is no network, so an edit is stored first and sent afterwards,
/// and until it has been sent it is newer than anything the server can say. The
/// rules that follow from that — what is queued, in what order it goes out, and
/// what happens when the server refuses — are what these are about.

/// A provider nobody calls: these tests are about what happens to a set, and
/// the token is only ever something the repository has to be holding.
final _oidcConfig = OidcConfig(
  clientId: 'test',
  issuer: Uri.parse('http://nowhere'),
  redirectUri: Uri.parse('http://localhost/'),
  nativeRedirectUri: Uri.parse('app.wvl.score://callback'),
  desktopRedirectUri: Uri.parse('http://localhost:7005/'),
  authorizationEndpoint: Uri.parse('http://nowhere/authorize'),
  tokenEndpoint: Uri.parse('http://nowhere/token'),
  userInfoEndpoint: Uri.parse('http://nowhere/userinfo'),
  healthzEndpoint: Uri.parse('http://nowhere/healthz'),
  rolesKey: 'roles',
);

/// An API that is not there, which is the case the whole design is for.
class _OfflineApi extends SetsApi {
  _OfflineApi() : super(ApiConfig(baseUrl: Uri.parse('http://nowhere/')));

  @override
  Future<bool> canBeReached() async => false;
}

/// An API that takes whatever it is given and hands it back.
class _WorkingApi extends SetsApi {
  _WorkingApi() : super(ApiConfig(baseUrl: Uri.parse('http://nowhere/')));

  final List<String> calls = [];
  final Map<String, Map<String, dynamic>> stored = {};

  /// What each song was written as, in order.
  final List<Map<String, Object?>> entryWrites = [];

  /// What a listing will answer with, whatever is actually stored.
  List<Map<String, dynamic>> answers = [];

  /// The change windows that were asked about, in order.
  final List<(DateTime?, DateTime?)> windows = [];

  @override
  Future<bool> canBeReached() async => true;

  @override
  Future<List<Map<String, dynamic>>> listSets(
      DateTime? since, DateTime? until, String token) async {
    calls.add('list');
    windows.add((since, until));
    return answers;
  }

  @override
  Future<Map<String, dynamic>> putSet(
      String setId, String token, Map<String, Object?> write) async {
    calls.add('putSet');
    return stored[setId] = {
      'id': setId,
      'title': write['title'],
      'description': write['description'],
      'shared_with': write['shared_with'],
      'is_owner': true,
      'entries': <Map<String, dynamic>>[],
      'last_changed_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> putEntry(String setId, String entryId,
      String token, Map<String, Object?> write) async {
    calls.add('putEntry');
    entryWrites.add(write);
    return {
      'id': entryId,
      'score_id': write['score_id'],
      'description': write['description'],
      'transposition': write['transposition'],
      'position': write['position'],
      'view': {'transposition': 0, 'hidden_parts': <String>[]},
    };
  }

  /// What each view was written as, in order.
  final List<Map<String, Object?>> viewWrites = [];

  @override
  Future<Map<String, dynamic>> putEntryView(String setId, String entryId,
      String token, Map<String, Object?> write) async {
    calls.add('putEntryView');
    viewWrites.add(write);
    // As the server does: a view written without a size is stored at the size
    // the score is written at.
    return {
      'transposition': write['transposition'],
      'hidden_parts': write['hidden_parts'],
      'zoom': write['zoom'] ?? 1,
    };
  }

  @override
  Future<void> deleteEntry(String setId, String entryId, String token) async {
    calls.add('deleteEntry');
  }

  @override
  Future<void> deleteSet(String setId, String token) async {
    calls.add('deleteSet');
  }

  @override
  Future<Map<String, dynamic>?> getSet(String setId, String token) async {
    calls.add('getSet');
    return stored[setId];
  }
}

/// An API that can be listed but whose writes do not get through — the network
/// dropping mid-sync. What is owed stays owed, which is the state the rule
/// about pulls is about.
class _WriteFailsApi extends _WorkingApi {
  @override
  Future<Map<String, dynamic>> putSet(
      String setId, String token, Map<String, Object?> write) {
    throw SetsApiException('nothing answered', null);
  }

  @override
  Future<Map<String, dynamic>> putEntry(String setId, String entryId,
      String token, Map<String, Object?> write) {
    throw SetsApiException('nothing answered', null);
  }
}

/// An API that refuses a write for a reason that will not pass.
class _RefusingApi extends _WorkingApi {
  @override
  Future<Map<String, dynamic>> putSet(
      String setId, String token, Map<String, Object?> write) {
    calls.add('putSet');
    throw SetsApiException('no', 403, {
      'errorCode': 'not_set_owner',
      'detail': 'that set belongs to somebody else',
    });
  }
}

/// An API that holds on to the first song written until it is let go, the way
/// a slow network does.
class _HeldEntryApi extends _WorkingApi {
  final Completer<void> reached = Completer<void>();
  final Completer<void> held = Completer<void>();

  @override
  Future<Map<String, dynamic>> putEntry(String setId, String entryId,
      String token, Map<String, Object?> write) async {
    if (!reached.isCompleted) {
      reached.complete();
      await held.future;
    }
    return super.putEntry(setId, entryId, token, write);
  }
}

/// A server that keeps a running order the way internal/set/save_entry.go does:
/// an entry written at a place is taken out of wherever it was and put back
/// there, at the end when that is beyond it.
class _OrderingApi extends _WorkingApi {
  final Map<String, List<String>> orders = {};

  @override
  Future<Map<String, dynamic>> putEntry(String setId, String entryId,
      String token, Map<String, Object?> write) async {
    final order = orders.putIfAbsent(setId, () => [])..remove(entryId);
    final at = (write['position']! as int).clamp(0, order.length);
    order.insert(at, entryId);
    return {...await super.putEntry(setId, entryId, token, write), 'position': at};
  }

  @override
  Future<void> deleteEntry(String setId, String entryId, String token) async {
    orders[setId]?.remove(entryId);
    await super.deleteEntry(setId, entryId, token);
  }

  @override
  Future<Map<String, dynamic>?> getSet(String setId, String token) async {
    calls.add('getSet');
    return {
      'id': setId,
      'is_owner': true,
      'entries': [
        for (final (index, id) in (orders[setId] ?? const <String>[]).indexed)
          {'id': id, 'score_id': id, 'position': index},
      ],
    };
  }
}

/// An API whose listing is made when it is asked for, and answered only once
/// it is let go — the way a slow network delivers an answer the server made
/// before a write that arrived after it.
class _SlowListingApi extends _WorkingApi {
  final Completer<void> asked = Completer<void>();
  final Completer<void> answer = Completer<void>();

  @override
  Future<List<Map<String, dynamic>>> listSets(
      DateTime? since, DateTime? until, String token) async {
    final made = await super.listSets(since, until, token);
    asked.complete();
    await answer.future;
    return made;
  }
}

/// An API that is there or not, as the test says.
class _SometimesThereApi extends _WorkingApi {
  bool there = false;

  @override
  Future<bool> canBeReached() async => there;

  /// The titles every write of a set sent, in order.
  final List<Object?> titlesWritten = [];

  @override
  Future<Map<String, dynamic>> putSet(
      String setId, String token, Map<String, Object?> write) {
    titlesWritten.add(write['title']);
    return super.putSet(setId, token, write);
  }
}

/// An API that refuses the token itself.
class _TokenRefusedApi extends _WorkingApi {
  @override
  Future<Map<String, dynamic>> putSet(
      String setId, String token, Map<String, Object?> write) {
    throw SetsApiException('the token is no good', 401);
  }
}

/// A provider that counts the tokens it was told to forget.
class _Counting extends _SignedIn {
  _Counting(super.store);

  int forgotten = 0;

  @override
  Future<void> forgetAccessToken() async => forgotten++;
}

/// A provider whose token cannot be had right now: a refresh that failed
/// because the network did.
class _TokenFails extends OidcApi {
  _TokenFails(
    LocalStore store,
  ) : super(_oidcConfig, store);

  @override
  Future<String?> getActiveAccessToken({bool signIn = true}) async =>
      throw Exception('the network went away');

  @override
  Future<bool> canBeReached() async => true;
}

/// A provider that always has a token to hand.
class _SignedIn extends OidcApi {
  _SignedIn(
    LocalStore store,
  ) : super(_oidcConfig, store);

  @override
  Future<String?> getActiveAccessToken({bool signIn = true}) async => 'a-token';

  @override
  Future<bool> canBeReached() async => true;
}

Future<(SetsRepository, LocalStore)> _repository(SetsApi api) async {
  final store = await LocalStore.inMemory();
  final repository = SetsRepository(store, api, _SignedIn(store));
  await repository.init();
  return (repository, store);
}

void main() {
  group('with nothing to send it to', () {
    test('a set is stored here and marked as owed', () async {
      final (sets, _) = await _repository(_OfflineApi());

      final saved = await sets.saveSet(title: 'Zomerbar');

      expect(sets.sets, hasLength(1));
      expect(saved.title, 'Zomerbar');
      expect(saved.pendingChange, PendingChange.write);
      expect(sets.hasPendingChanges, isTrue);
    });

    test('edits made one straight after another all stay', () async {
      // Each edit first takes in what other tabs stored. What this tab wrote a
      // moment before must not be put back to what the store held before it.
      final (sets, store) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      await sets.saveEntry(set.id, id: 'a', scoreId: 'a');
      await sets.saveEntry(set.id, id: 'b', scoreId: 'b');

      await Future.wait([
        sets.saveEntry(set.id, id: 'a', description: 'capo 2'),
        sets.saveEntry(set.id, id: 'b', description: 'straight into the next'),
        sets.saveSet(id: set.id, title: 'Zomerbar, renamed'),
      ]);

      final reopened = SetsRepository(store, _OfflineApi(), _SignedIn(store));
      await reopened.init();
      for (final now in [sets.getSet(set.id)!, reopened.getSet(set.id)!]) {
        expect(now.title, 'Zomerbar, renamed');
        expect(now.entries.map((entry) => entry.description),
            ['capo 2', 'straight into the next']);
      }
    });

    test('a set survives being read back off the device', () async {
      final store = await LocalStore.inMemory();
      final first = SetsRepository(store, _OfflineApi(), _SignedIn(store));
      await first.init();
      await first.saveSet(title: 'Zomerbar', description: 'two sets of forty');

      // The same device, opened again.
      final second = SetsRepository(store, _OfflineApi(), _SignedIn(store));
      await second.init();

      expect(second.sets, hasLength(1));
      expect(second.sets.first.title, 'Zomerbar');
      expect(second.sets.first.description, 'two sets of forty');
      expect(second.hasPendingChanges, isTrue,
          reason: 'what was owed is still owed');
    });

    test('a song added at a gig is queued behind the set it is in', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      final withSong = await sets.saveEntry(set.id, scoreId: 'score-1');

      expect(withSong.entries, hasLength(1));
      expect(withSong.entries.first.scoreId, 'score-1');
      expect(withSong.pendingEntries, hasLength(1));
      expect(withSong.entries.first.synced, isFalse);
    });

    test('a song taken out again before it was ever sent is simply gone',
        () async {
      // There is no row on the server to remove, so there is nothing to tell it
      // about.
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      final added = await sets.saveEntry(set.id, scoreId: 'score-1');
      final removed = await sets.deleteEntry(set.id, added.entries.first.id);

      expect(removed.entries, isEmpty);
      expect(removed.pendingEntries, isEmpty);
    });

    test('the running order is closed up around a song put into it', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      await sets.saveEntry(set.id, scoreId: 'a');
      await sets.saveEntry(set.id, scoreId: 'b');
      final three = await sets.saveEntry(set.id, scoreId: 'c', position: 1);

      expect([for (final entry in three.entries) entry.scoreId],
          ['a', 'c', 'b']);
    });

    test('a song is moved by writing it at another place', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      await sets.saveEntry(set.id, scoreId: 'a');
      await sets.saveEntry(set.id, scoreId: 'b');
      var now = await sets.saveEntry(set.id, scoreId: 'c');

      final last = now.entries.last;
      now = await sets.saveEntry(set.id, id: last.id, position: 0);

      expect([for (final entry in now.entries) entry.scoreId], ['c', 'a', 'b']);
    });

    test('a song that is written without being moved stays where it is',
        () async {
      // A note or a key is written without a place, and taking that for the
      // end would send the song to the back of the gig for everyone.
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      await sets.saveEntry(set.id, scoreId: 'a');
      await sets.saveEntry(set.id, scoreId: 'b');
      var now = await sets.saveEntry(set.id, scoreId: 'c');

      final first = now.entries.first;
      now = await sets.saveEntry(set.id, id: first.id, description: 'capo 2');
      now = await sets.saveEntry(set.id, id: first.id, transposition: 2);

      expect([for (final entry in now.entries) entry.scoreId], ['a', 'b', 'c']);
      expect(now.entries.first.description, 'capo 2');
      expect(now.entries.first.transposition, 2);
    });
  });

  group('how a player reads a song', () {
    test('includes how big they draw it, which a change of key leaves alone',
        () async {
      // A view is written whole, and the server stores one sent without its
      // size at the size the score is written at.
      final api = _WorkingApi();
      final (sets, _) = await _repository(api);
      final set = await sets.saveSet(title: 'Zomerbar');
      final added = await sets.saveEntry(set.id, scoreId: 'score-1');
      final entryId = added.entries.first.id;

      await sets.saveEntryView(set.id, entryId, transposition: 2, zoom: 1.5);
      final read = await sets.saveEntryView(set.id, entryId, transposition: 3);

      expect(read.entries.first.view.zoom, 1.5);
      expect(api.viewWrites.last, containsPair('zoom', 1.5));
    });

    test('is theirs, and is owed to the server on its own', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      final added = await sets.saveEntry(set.id, scoreId: 'score-1');
      final entryId = added.entries.first.id;

      final read = await sets.saveEntryView(set.id, entryId,
          transposition: 5, hiddenParts: ['P2']);

      expect(read.entries.first.view.transposition, 5);
      expect(read.entries.first.view.hiddenParts, ['P2']);
      expect(read.pendingViews, [entryId]);
    });

    test('is counted on top of the key the band plays it in', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      final added =
          await sets.saveEntry(set.id, scoreId: 'score-1', transposition: -2);
      final entryId = added.entries.first.id;

      final read =
          await sets.saveEntryView(set.id, entryId, transposition: 7);

      // The band a tone down, the player a fifth up from there.
      expect(read.entries.first.readAt, 5);
    });

    test('never asks the score for a key it cannot be shown in', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      final added =
          await sets.saveEntry(set.id, scoreId: 'score-1', transposition: 10);
      final entryId = added.entries.first.id;

      final read =
          await sets.saveEntryView(set.id, entryId, transposition: 10);

      expect(read.entries.first.transposition + read.entries.first.view.transposition,
          20);
      expect(read.entries.first.readAt, 12, reason: 'as far as it goes');
    });

    test('goes with the song when the song leaves the set', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar');
      final added = await sets.saveEntry(set.id, scoreId: 'score-1');
      final entryId = added.entries.first.id;
      await sets.saveEntryView(set.id, entryId, transposition: 3);

      final gone = await sets.deleteEntry(set.id, entryId);

      expect(gone.pendingViews, isEmpty,
          reason: 'a view of a song nobody plays is not owed to anybody');
    });

    test('may be written by somebody the set is only shared with', () async {
      // A view says nothing about the set and changes nothing anybody else
      // sees, so a player who cannot change a note of the running order can
      // still say what key they read it in.
      final (sets, store) = await _repository(_OfflineApi());
      await store.writeSets([
        ScoreSet(
          id: 'theirs',
          title: "Somebody else's gig",
          isOwner: false,
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          entries: const [SetEntry(id: 'e1', scoreId: 'score-1', synced: true)],
        ).toJson(),
      ]);
      await sets.init();

      final read =
          await sets.saveEntryView('theirs', 'e1', transposition: 4);

      expect(read.entries.first.view.transposition, 4);
      expect(read.pendingViews, ['e1']);
    });

    test('but the running order is not theirs to change', () async {
      final (sets, store) = await _repository(_OfflineApi());
      await store.writeSets([
        ScoreSet(
          id: 'theirs',
          title: "Somebody else's gig",
          isOwner: false,
          lastChangedAt: DateTime.now(),
        ).toJson(),
      ]);
      await sets.init();

      expect(() => sets.saveEntry('theirs', scoreId: 'score-1'),
          throwsA(isA<StateError>()));
      expect(() => sets.deleteSet('theirs'), throwsA(isA<StateError>()));
    });
  });

  group('when the server can be reached again', () {
    test('what is owed goes out set, then songs, then views', () async {
      // Each of them is written against the one before it: an entry against a
      // set, a view against an entry.
      final api = _WorkingApi();
      final (sets, _) = await _repository(_OfflineApi());

      final set = await sets.saveSet(title: 'Zomerbar');
      final added = await sets.saveEntry(set.id, scoreId: 'score-1');
      await sets.saveEntryView(set.id, added.entries.first.id,
          transposition: 2);

      // The same device, now with a network.
      final store = await LocalStore.inMemory();
      final online = SetsRepository(store, api, _SignedIn(store));
      await store.writeSets([sets.getSet(set.id)!.toJson()]);
      await online.init();

      await online.syncWithApi();

      expect(api.calls.where((call) => call != 'list').toList(),
          ['putSet', 'putEntry', 'putEntryView']);
      expect(online.hasPendingChanges, isFalse);
    });

    test('a song played from paper goes out as having no score', () async {
      // Not as the text `null`, which the server would take for the id of a
      // score and refuse.
      final api = _WorkingApi();
      final (sets, _) = await _repository(_OfflineApi());

      final set = await sets.saveSet(title: 'Zomerbar');
      final added = await sets.saveEntry(set.id, description: 'Happy birthday');
      final written = await sets.saveEntry(set.id,
          id: added.entries.first.id, description: 'Happy birthday, twice');

      final store = await LocalStore.inMemory();
      final online = SetsRepository(store, api, _SignedIn(store));
      await store.writeSets([sets.getSet(set.id)!.toJson()]);
      await online.init();
      await online.syncWithApi();

      expect(written.entries.single.scoreId, isNull);
      expect(api.entryWrites, isNotEmpty);
      for (final write in api.entryWrites) {
        expect(write, containsPair('score_id', null));
      }
      expect(online.getSet(set.id)!.entries.single.scoreId, isNull);
    });

    test('a set the server refuses is taken back and reported', () async {
      final api = _RefusingApi();
      final store = await LocalStore.inMemory();
      final sets = SetsRepository(store, api, _SignedIn(store));
      await sets.init();

      final problems = <SyncProblem>[];
      sets.addSyncProblemListener(problems.add);

      await sets.saveSet(title: 'Not mine');

      expect(problems, hasLength(1));
      expect(problems.first.error.errorCode, 'not_set_owner');
      expect(sets.hasPendingChanges, isFalse,
          reason: 'a write the server will never take is not owed forever');
    });

    test('a new set the server refuses is kept with the songs put into it',
        () async {
      // It was never on the server, so there is nothing there to take it back
      // to: what the player made stays, and its songs wait for a write of the
      // set the server will take rather than being sent into nothing.
      final api = _RefusingApi();
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Zomerbar', sharedWith: ['bas']);
      await sets.saveEntry(set.id, scoreId: 'score-1');

      final store = await LocalStore.inMemory();
      final online = SetsRepository(store, api, _SignedIn(store));
      await store.writeSets([sets.getSet(set.id)!.toJson()]);
      await online.init();
      final problems = <SyncProblem>[];
      online.addSyncProblemListener(problems.add);

      await online.syncWithApi();

      final now = online.getSet(set.id);
      expect(problems, hasLength(1));
      expect(now, isNotNull, reason: 'a refused write is not a deleted set');
      expect(now!.entries, hasLength(1));
      expect(now.pendingChange, isNull);
      expect(now.pendingEntries, hasLength(1));
      expect(api.calls, isNot(contains('putEntry')));
    });

    test('a write whose token could not be had stays queued', () async {
      // A refresh that failed because the network did says nothing about the
      // set: the edit is stored, and goes out with the next sync rather than
      // being reported as not saved.
      final store = await LocalStore.inMemory();
      final sets = SetsRepository(store, _WorkingApi(), _TokenFails(store));
      await sets.init();

      final saved = await sets.saveSet(title: 'Zomerbar');
      final added = await sets.saveEntry(saved.id, scoreId: 'score-1');

      expect(added.pendingChange, PendingChange.write);
      expect(added.entries, hasLength(1));
      expect(sets.hasPendingChanges, isTrue);
    });

    test('a song taken out while another is on its way is taken out there too',
        () async {
      // The queue that went out still has the write of the song that was taken
      // out; settling that stale write must not take the delete with it.
      final api = _HeldEntryApi();
      final store = await LocalStore.inMemory();
      await store.writeSets([
        ScoreSet(
          id: 'mine',
          title: 'Zomerbar',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          entries: const [
            SetEntry(id: 'a', scoreId: 'score-a', synced: true),
            SetEntry(id: 'e', scoreId: 'score-e', synced: true),
          ],
          pendingEntries: const [
            PendingEntry('a', PendingChange.write),
            PendingEntry('e', PendingChange.write),
          ],
        ).toJson(),
      ]);
      final sets = SetsRepository(store, api, _SignedIn(store));
      await sets.init();

      final syncing = sets.syncWithApi();
      await api.reached.future;
      final deleting = sets.deleteEntry('mine', 'e');
      api.held.complete();
      await syncing;
      await deleting;

      expect(api.calls, contains('deleteEntry'));
      expect([for (final entry in sets.getSet('mine')!.entries) entry.id],
          ['a']);
      expect(sets.hasPendingChanges, isFalse);
    });

    test('a set that was written here is not overwritten by a sync', () async {
      // What is still owed was written after the last thing the server said, so
      // it is the newer of the two and the answer is out of date the moment it
      // arrives. The write is made to fail here, because a write that got
      // through would have settled the disagreement honestly.
      final api = _WriteFailsApi();
      final store = await LocalStore.inMemory();
      final sets = SetsRepository(store, api, _SignedIn(store));
      await sets.init();

      await store.writeSets([
        ScoreSet(
          id: 'mine',
          title: 'What I typed',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          pendingChange: PendingChange.write,
        ).toJson(),
      ]);
      await sets.init();

      api.answers = [
        {
          'id': 'mine',
          'title': 'What the server has',
          'description': '',
          'entries': <Map<String, dynamic>>[],
          'shared_with': <String>[],
          'is_owner': true,
          'last_changed_at': DateTime.now().toIso8601String(),
        }
      ];

      await sets.syncWithApi();

      expect(sets.getSet('mine')!.title, 'What I typed');
      expect(sets.getSet('mine')!.pendingChange, PendingChange.write,
          reason: 'it is still owed, so it is still the newer of the two');
    });

    test('a running order written here survives what a sync brings in',
        () async {
      final api = _WriteFailsApi();
      final store = await LocalStore.inMemory();
      final sets = SetsRepository(store, api, _SignedIn(store));
      await store.writeSets([
        ScoreSet(
          id: 'mine',
          title: 'Zomerbar',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          entries: const [
            SetEntry(id: 'e1', scoreId: 'here-only'),
          ],
          pendingEntries: const [PendingEntry('e1', PendingChange.write)],
        ).toJson(),
      ]);
      await sets.init();

      api.answers = [
        {
          'id': 'mine',
          'title': 'Zomerbar',
          'description': '',
          'entries': [
            {
              'id': 'e9',
              'score_id': 'somebody-elses',
              'description': '',
              'transposition': 0,
              'view': {'transposition': 0, 'hidden_parts': <String>[]},
            }
          ],
          'shared_with': <String>[],
          'is_owner': true,
          'last_changed_at': DateTime.now().toIso8601String(),
        }
      ];

      await sets.syncWithApi();

      // The song that was added here is still in the set: the answer cannot
      // know about it, and half a running order is not one.
      expect(
        sets.getSet('mine')!.entries.any((entry) => entry.scoreId == 'here-only'),
        isTrue,
      );      // And the song another device put in is not lost either: the next sync
      // only asks about what changed after this one.
      expect(
        sets.getSet('mine')!.entries.map((entry) => entry.scoreId),
        ['here-only', 'somebody-elses'],
      );
    });

    group('a running order arranged offline is the one the band gets', () {
      Future<(SetsRepository, _OrderingApi)> offlineThenOnline(
        List<String> onTheServer,
        Future<void> Function(SetsRepository offline) arrange,
      ) async {
        final store = await LocalStore.inMemory();
        await store.writeSets([
          ScoreSet(
            id: 'mine',
            title: 'Zomerbar',
            lastChangedAt: DateTime.now(),
            lastSyncedAt: DateTime.now(),
            entries: [
              for (final id in onTheServer)
                SetEntry(id: id, scoreId: id, synced: true),
            ],
          ).toJson(),
        ]);
        final offline = SetsRepository(store, _OfflineApi(), _SignedIn(store));
        await offline.init();
        await arrange(offline);

        final api = _OrderingApi()..orders['mine'] = [...onTheServer];
        final online = SetsRepository(store, api, _SignedIn(store));
        await online.init();
        await online.syncWithApi();
        return (online, api);
      }

      test('a song added and one taken out', () async {
        // The song is sent while the one taken out is still in the server's
        // order, so where it goes is counted behind the song it follows.
        final (online, api) = await offlineThenOnline(['a', 'x', 'b'],
            (offline) async {
          await offline.saveEntry('mine', id: 'n', scoreId: 'n');
          await offline.deleteEntry('mine', 'x');
        });

        expect(api.orders['mine'], ['a', 'b', 'n']);
        expect(online.getSet('mine')!.entries.map((entry) => entry.id),
            ['a', 'b', 'n']);
      });

      test('a song added and another moved behind it', () async {
        final (online, api) = await offlineThenOnline(['a', 'b', 'c'],
            (offline) async {
          await offline.saveEntry('mine', id: 'n', scoreId: 'n');
          await offline.saveEntry('mine', id: 'a', position: 3);
        });

        expect(api.orders['mine'], ['b', 'c', 'n', 'a']);
        expect(online.getSet('mine')!.entries.map((entry) => entry.id),
            ['b', 'c', 'n', 'a']);
      });

      test('a song added and another then moved in front of it', () async {
        // Sent in the order it was done, the new song would be placed behind
        // where the moved one used to be, and stay there once it had moved.
        final (online, api) = await offlineThenOnline(['a', 'b', 'c'],
            (offline) async {
          await offline.saveEntry('mine', id: 'e', scoreId: 'e');
          await offline.saveEntry('mine', id: 'a', position: 2);
        });

        expect(api.orders['mine'], ['b', 'c', 'a', 'e']);
        expect(online.getSet('mine')!.entries.map((entry) => entry.id),
            ['b', 'c', 'a', 'e']);
      });

      test('two songs moved, the second in front of the first', () async {
        final (online, api) = await offlineThenOnline(['a', 'b', 'c', 'd'],
            (offline) async {
          await offline.saveEntry('mine', id: 'c', position: 3);
          await offline.saveEntry('mine', id: 'a', position: 2);
        });

        expect(api.orders['mine'], ['b', 'd', 'a', 'c']);
        expect(online.getSet('mine')!.entries.map((entry) => entry.id),
            ['b', 'd', 'a', 'c']);
      });
    });

    test('a pull made before a write and answered after it does not undo it',
        () async {
      final api = _SlowListingApi();
      final store = await LocalStore.inMemory();
      final before = ScoreSet(
        id: 'mine',
        title: 'Old title',
        lastChangedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );
      await store.writeSets([before.toJson()]);
      final sets = SetsRepository(store, api, _SignedIn(store));
      await sets.init();

      // The server's answer is made while the set still has its old title...
      api.answers = [
        {...before.toJson(), 'is_owner': true, 'entries': <Object?>[]},
      ];
      final syncing = sets.syncWithApi();
      await api.asked.future;
      // ...the new title is written, and taken, while it is on its way...
      await sets.saveSet(id: 'mine', title: 'New title');
      // ...and the old answer arrives after.
      api.answer.complete();
      await syncing;

      expect(sets.getSet('mine')!.title, 'New title');
    });

    test('what another tab stored is not sent back over by this one', () async {
      // Two tabs of the web app over the one store. This one was offline when
      // the set was renamed; the other sent that, and then renamed it again.
      final store = await LocalStore.inMemory();
      await store.writeSets([
        ScoreSet(
          id: 'mine',
          title: 'Before',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      final api = _SometimesThereApi();
      final thisTab = SetsRepository(store, api, _SignedIn(store));
      await thisTab.init();
      await thisTab.saveSet(id: 'mine', title: 'Offline');

      api.there = true;
      final otherTab = SetsRepository(store, api, _SignedIn(store));
      await otherTab.init();
      await otherTab.syncWithApi();
      await otherTab.saveSet(id: 'mine', title: 'Latest');

      await thisTab.syncWithApi();

      expect(api.titlesWritten, ['Offline', 'Latest']);
      expect(thisTab.getSet('mine')!.title, 'Latest');
    });

    test('a sync in another tab does not drop a song put in here meanwhile',
        () async {
      final store = await LocalStore.inMemory();
      final before = ScoreSet(
        id: 'mine',
        title: 'Zomerbar',
        lastChangedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );
      await store.writeSets([before.toJson()]);
      final api = _SlowListingApi()
        ..answers = [
          {...before.toJson(), 'is_owner': true, 'entries': <Object?>[]},
        ];
      final otherTab = SetsRepository(store, api, _SignedIn(store));
      await otherTab.init();
      final thisTab = SetsRepository(store, _OfflineApi(), _SignedIn(store));
      await thisTab.init();

      // The other tab's answer is on its way when the song is put in here.
      final syncing = otherTab.syncWithApi();
      await api.asked.future;
      await thisTab.saveEntry('mine', id: 'n', scoreId: 'n');
      api.answer.complete();
      await syncing;

      await thisTab.saveSet(id: 'mine', title: 'Zomerbar 2');
      expect(thisTab.getSet('mine')!.entries.map((entry) => entry.id), ['n']);
      expect(thisTab.getSet('mine')!.pendingEntries.map((owed) => owed.id),
          ['n']);
    });

    test('a push in another tab does not drop a song put in here meanwhile',
        () async {
      final store = await LocalStore.inMemory();
      await store.writeSets([
        ScoreSet(
          id: 'mine',
          title: 'Zomerbar',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      final offline = SetsRepository(store, _OfflineApi(), _SignedIn(store));
      await offline.init();
      await offline.saveEntry('mine', id: 'x', scoreId: 'x');

      final api = _HeldEntryApi();
      final otherTab = SetsRepository(store, api, _SignedIn(store));
      await otherTab.init();
      final thisTab = SetsRepository(store, _OfflineApi(), _SignedIn(store));
      await thisTab.init();

      // The other tab sends song x, and song n is put in here while it is out.
      final syncing = otherTab.syncWithApi();
      await api.reached.future;
      await thisTab.saveEntry('mine', id: 'n', scoreId: 'n');
      api.held.complete();
      await syncing;

      await thisTab.saveSet(id: 'mine', title: 'Zomerbar 2');
      expect(thisTab.getSet('mine')!.entries.map((entry) => entry.id),
          ['x', 'n']);
      expect(thisTab.getSet('mine')!.pendingEntries.map((owed) => owed.id),
          contains('n'));

      // Song x, whose answer was dropped for it, goes again and is settled.
      final again = SetsRepository(store, _WorkingApi(), _SignedIn(store));
      await again.init();
      await again.syncWithApi();
      expect(again.getSet('mine')!.pendingEntries, isEmpty);
      expect(again.getSet('mine')!.entries.map((entry) => entry.id),
          ['x', 'n']);
    });

    test('a token the API refuses is forgotten, and the write stays queued',
        () async {
      final store = await LocalStore.inMemory();
      final oidc = _Counting(store);
      final sets = SetsRepository(store, _TokenRefusedApi(), oidc);
      await sets.init();

      final saved = await sets.saveSet(title: 'Zomerbar');

      expect(oidc.forgotten, 1);
      expect(sets.getSet(saved.id)!.pendingChange, PendingChange.write);
    });

    test('a song goes to the place it has among the songs the server has',
        () async {
      // Two songs put at the top of the set while offline: they go out in the
      // order they run in here, so the second is placed behind the first
      // rather than behind a song the server has not heard of yet.
      final store = await LocalStore.inMemory();
      await store.writeSets([
        ScoreSet(
          id: 'mine',
          title: 'Zomerbar',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          entries: const [SetEntry(id: 'a', scoreId: 'a', synced: true)],
        ).toJson(),
      ]);
      final offline = SetsRepository(store, _OfflineApi(), _SignedIn(store));
      await offline.init();
      await offline.saveEntry('mine', id: 'x', scoreId: 'x', position: 0);
      await offline.saveEntry('mine', id: 'y', scoreId: 'y', position: 0);

      final api = _WorkingApi();
      final online = SetsRepository(store, api, _SignedIn(store));
      await online.init();
      await online.syncWithApi();

      expect(api.entryWrites.map((write) => write['position']), [0, 1]);
      expect(online.getSet('mine')!.entries.map((entry) => entry.id),
          ['y', 'x', 'a']);
    });
  });

  group('the change window', () {
    // The server's clock, which is not this device's: here it is an hour
    // behind, as a server is for a tablet whose clock was never set.
    final serverNow = DateTime.now().toUtc().subtract(const Duration(hours: 1));

    Map<String, dynamic> answer(String id, {DateTime? changedAt}) => {
          'id': id,
          'title': id,
          'description': '',
          'entries': <Map<String, dynamic>>[],
          'shared_with': <String>[],
          'is_owner': true,
          'last_changed_at': (changedAt ?? serverNow).toIso8601String(),
        };

    test('the next one starts at the newest change the server answered with,'
        ' less the overlap', () async {
      // Not this device's clock: an hour ahead, it would start the next window
      // past everything the server changes in that hour.
      final api = _WorkingApi();
      final (sets, _) = await _repository(api);

      api.answers = [
        answer('a', changedAt: serverNow.subtract(const Duration(minutes: 5))),
        answer('b'),
      ];
      await sets.syncWithApi();
      api.answers = [];
      await sets.syncWithApi();

      final (secondSince, _) = api.windows.last;
      expect(secondSince, serverNow.subtract(pullOverlap));
      expect(sets.getSet('b')!.lastSyncedAt, serverNow);
    });

    test('a set written outside a pull does not move it', () async {
      // Another set may have changed since the last pull, and a watermark
      // moved to the moment of this write would have the next pull skip it.
      final api = _WorkingApi();
      final (sets, _) = await _repository(api);

      api.answers = [answer('a')];
      await sets.syncWithApi();

      api.answers = [];
      final written = await sets.saveSet(title: 'Written later');
      await sets.syncWithApi();

      final (since, _) = api.windows.last;
      expect(since, serverNow.subtract(pullOverlap));
      expect(sets.getSet(written.id)!.lastSyncedAt, isNotNull,
          reason: 'the server has it, so a delete has to be sent there');
    });
  });

  group('a set that is deleted', () {
    test('is kept as a headstone rather than forgotten', () async {
      // A sync only asks about what changed since the last one, so a set that
      // was simply forgotten here would be fetched straight back in as
      // something new.
      final (sets, store) = await _repository(_OfflineApi());
      await store.writeSets([
        ScoreSet(
          id: 'gone',
          title: 'Last summer',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      await sets.init();

      await sets.deleteSet('gone');

      expect(sets.getSet('gone'), isNull);
      expect(sets.sets, isEmpty);
      expect(sets.hasPendingChanges, isTrue,
          reason: 'the server has to be told');
    });

    test('and takes what was to go into it with it', () async {
      final (sets, store) = await _repository(_OfflineApi());
      await store.writeSets([
        ScoreSet(
          id: 'gone',
          title: 'Last summer',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          entries: const [SetEntry(id: 'e1', scoreId: 'score-1')],
          pendingEntries: const [PendingEntry('e1', PendingChange.write)],
        ).toJson(),
      ]);
      await sets.init();

      await sets.deleteSet('gone');

      final kept = (await store.readSets()).map(ScoreSet.fromJson).single;
      expect(kept.pendingChange, PendingChange.delete);
      expect(kept.pendingEntries, isEmpty,
          reason: 'there is no set left on the server to put them into');
    });

    test('and was never sent is nothing to tell the server about', () async {
      final (sets, _) = await _repository(_OfflineApi());
      final set = await sets.saveSet(title: 'Typed and thrown away');

      await sets.deleteSet(set.id);

      expect(sets.hasPendingChanges, isFalse);
    });

    test('comes back when it is written again', () async {
      final (sets, store) = await _repository(_OfflineApi());
      await store.writeSets([
        ScoreSet(
          id: 'gone',
          title: 'Last summer',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      await sets.init();
      await sets.deleteSet('gone');

      final back = await sets.saveSet(id: 'gone', title: 'Back on');

      expect(back.deletedAt, isNull);
      expect(sets.getSet('gone'), isNotNull);
    });
  });

  test('an address it is shared with is written the way the API reads one',
      () async {
    final (sets, _) = await _repository(_OfflineApi());

    final set = await sets.saveSet(
      title: 'Zomerbar',
      sharedWith: ['  Bas@Example.com ', 'bas@example.com', '', 'ann@example.com'],
    );

    expect(set.sharedWith, ['bas@example.com', 'ann@example.com']);
  });
}

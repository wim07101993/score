import 'package:flutter_test/flutter_test.dart';
import 'package:score/config.dart';
import 'package:score/data/local_store.dart';
import 'package:score/domains/auth/oidc_api.dart';
import 'package:score/domains/sets/api.dart';
import 'package:score/domains/sets/models.dart';
import 'package:score/domains/sets/repository.dart';

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

  /// What a listing will answer with, whatever is actually stored.
  List<Map<String, dynamic>> answers = [];

  @override
  Future<bool> canBeReached() async => true;

  @override
  Future<List<Map<String, dynamic>>> listSets(
      DateTime? since, DateTime? until, String token) async {
    calls.add('list');
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
    return {
      'id': entryId,
      'score_id': write['score_id'],
      'description': write['description'],
      'transposition': write['transposition'],
      'position': write['position'],
      'view': {'transposition': 0, 'hidden_parts': <String>[]},
    };
  }

  @override
  Future<Map<String, dynamic>> putEntryView(String setId, String entryId,
      String token, Map<String, Object?> write) async {
    calls.add('putEntryView');
    return {
      'transposition': write['transposition'],
      'hidden_parts': write['hidden_parts'],
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
      String setId, String token, Map<String, Object?> write) async {
    throw SetsApiException('nothing answered', null);
  }

  @override
  Future<Map<String, dynamic>> putEntry(String setId, String entryId,
      String token, Map<String, Object?> write) async {
    throw SetsApiException('nothing answered', null);
  }
}

/// An API that refuses a write for a reason that will not pass.
class _RefusingApi extends _WorkingApi {
  @override
  Future<Map<String, dynamic>> putSet(
      String setId, String token, Map<String, Object?> write) async {
    calls.add('putSet');
    throw SetsApiException('no', 403, {
      'errorCode': 'not_set_owner',
      'detail': 'that set belongs to somebody else',
    });
  }
}

/// A provider that always has a token to hand.
class _SignedIn extends OidcApi {
  _SignedIn(LocalStore store) : super(_oidcConfig, store);

  @override
  Future<String?> getActiveAccessToken() async => 'a-token';

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
  });

  group('how a player reads a song', () {
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
          title: 'Somebody else\'s gig',
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
          title: 'Somebody else\'s gig',
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
      );
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

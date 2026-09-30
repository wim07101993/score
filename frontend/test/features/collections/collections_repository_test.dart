import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/sembast/local_store.dart';

/// What a collection does when the server is not there, and when it is again.
///
/// A collection is filled in where the book is, which is where there is no
/// network, so an edit is stored first and sent afterwards, and until it has
/// been sent it is newer than anything the server can say. On top of what a
/// set does, a collection has one rule of its own — a score is in it at most
/// once — and pieces that have no score at all, which have to be called
/// something. Those are what these are about.

/// A provider nobody calls: these tests are about what happens to a
/// collection, and the token is only ever something the repository has to be
/// holding.
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
class _OfflineApi extends CollectionsApi {
  _OfflineApi() : super(ApiConfig(baseUrl: Uri.parse('http://nowhere/')));

  @override
  Future<bool> canBeReached() async => false;
}

/// An API that keeps what it is given, the way the server does, and holds a
/// collection to having a score in it once.
class _WorkingApi extends CollectionsApi {
  _WorkingApi() : super(ApiConfig(baseUrl: Uri.parse('http://nowhere/')));

  final List<String> calls = [];

  /// The collections as the server has them.
  final Map<String, Map<String, dynamic>> stored = {};

  /// What each piece was written as, in order.
  final List<Map<String, Object?>> entryWrites = [];

  /// What each view was written as, in order.
  final List<Map<String, Object?>> viewWrites = [];

  /// What a listing will answer with, whatever is actually stored.
  List<Map<String, dynamic>> answers = [];

  /// The change windows that were asked about, in order.
  final List<(DateTime?, DateTime?)> windows = [];

  @override
  Future<bool> canBeReached() async => true;

  @override
  Future<List<Map<String, dynamic>>> listCollections(
      DateTime? since, DateTime? until, String token) async {
    calls.add('list');
    windows.add((since, until));
    return answers;
  }

  @override
  Future<Map<String, dynamic>> putCollection(
      String collectionId, String token, Map<String, Object?> write) async {
    calls.add('putCollection');
    final entries = stored[collectionId]?['entries'] ?? <Map<String, dynamic>>[];
    return stored[collectionId] = {
      'id': collectionId,
      'title': write['title'],
      'description': write['description'],
      'shared_with': write['shared_with'],
      'is_owner': true,
      'entries': entries,
      'last_changed_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> putEntry(String collectionId, String entryId,
      String token, Map<String, Object?> write) async {
    calls.add('putEntry');
    entryWrites.add(write);
    final entries =
        (stored[collectionId]!['entries'] as List).cast<Map<String, dynamic>>();
    final scoreId = write['score_id'];
    final holder = entries
        .where((entry) =>
            scoreId != null &&
            entry['score_id'] == scoreId &&
            entry['id'] != entryId)
        .firstOrNull;
    if (holder != null) {
      throw CollectionsApiException('conflict', 409, {
        'errorCode': 'score_already_in_collection',
        'entryId': holder['id'],
      });
    }
    final entry = {
      'id': entryId,
      'score_id': scoreId,
      'description': write['description'],
      'transposition': write['transposition'],
      'view': {'transposition': 0, 'hidden_parts': <String>[], 'zoom': 1},
    };
    entries
      ..removeWhere((candidate) => candidate['id'] == entryId)
      ..add(entry);
    return entry;
  }

  @override
  Future<Map<String, dynamic>> putEntryView(String collectionId,
      String entryId, String token, Map<String, Object?> write) async {
    calls.add('putEntryView');
    viewWrites.add(write);
    return {
      'transposition': write['transposition'],
      'hidden_parts': write['hidden_parts'],
      'zoom': write['zoom'],
    };
  }

  @override
  Future<void> deleteEntry(
      String collectionId, String entryId, String token) async {
    calls.add('deleteEntry');
  }

  @override
  Future<void> deleteCollection(String collectionId, String token) async {
    calls.add('deleteCollection');
  }

  @override
  Future<Map<String, dynamic>?> getCollection(
      String collectionId, String token) async {
    calls.add('getCollection');
    return stored[collectionId];
  }
}

/// An API that can be listed but whose writes do not get through — the network
/// dropping mid-sync.
class _WriteFailsApi extends _WorkingApi {
  @override
  Future<Map<String, dynamic>> putCollection(
      String collectionId, String token, Map<String, Object?> write) {
    throw CollectionsApiException('nothing answered', null);
  }

  @override
  Future<Map<String, dynamic>> putEntry(String collectionId, String entryId,
      String token, Map<String, Object?> write) {
    throw CollectionsApiException('nothing answered', null);
  }
}

/// An API that refuses a write for a reason that will not pass.
class _RefusingApi extends _WorkingApi {
  @override
  Future<Map<String, dynamic>> putCollection(
      String collectionId, String token, Map<String, Object?> write) {
    calls.add('putCollection');
    throw CollectionsApiException('no', 403, {
      'errorCode': 'not_collection_owner',
      'detail': 'that collection belongs to somebody else',
    });
  }
}

/// An API whose listing is made when it is asked for, and answered only once
/// it is let go — the way a slow network delivers an answer the server made
/// before a write that arrived after it.
class _SlowListingApi extends _WorkingApi {
  final Completer<void> asked = Completer<void>();
  final Completer<void> answer = Completer<void>();

  @override
  Future<List<Map<String, dynamic>>> listCollections(
      DateTime? since, DateTime? until, String token) async {
    final made = await super.listCollections(since, until, token);
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

  /// The titles every write of a collection sent, in order.
  final List<Object?> titlesWritten = [];

  @override
  Future<Map<String, dynamic>> putCollection(
      String collectionId, String token, Map<String, Object?> write) {
    titlesWritten.add(write['title']);
    return super.putCollection(collectionId, token, write);
  }
}

/// An API that refuses the token itself.
class _TokenRefusedApi extends _WorkingApi {
  @override
  Future<Map<String, dynamic>> putCollection(
      String collectionId, String token, Map<String, Object?> write) {
    throw CollectionsApiException('the token is no good', 401);
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
class _TokenFails extends _SignedIn {
  _TokenFails(super.store);

  @override
  Future<String?> getActiveAccessToken({bool signIn = true}) async =>
      throw Exception('the network went away');
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

Future<(CollectionsRepository, LocalStore)> _repository(
    CollectionsApi api) async {
  final store = await LocalStore.inMemory();
  final repository = CollectionsRepository(store, api, _SignedIn(store));
  await repository.init();
  return (repository, store);
}

/// What was stored on one device, opened on the same device with a network.
Future<CollectionsRepository> _online(
    CollectionsRepository offline, CollectionsApi api) async {
  final store = await LocalStore.inMemory();
  await store.writeCollections([
    for (final collection in offline.collections) collection.toJson(),
  ]);
  final online = CollectionsRepository(store, api, _SignedIn(store));
  await online.init();
  return online;
}

void main() {
  group('with nothing to send it to', () {
    test('a collection is stored here and marked as owed', () async {
      final (collections, _) = await _repository(_OfflineApi());

      final saved = await collections.saveCollection(title: 'The Real Book');

      expect(collections.collections, hasLength(1));
      expect(saved.title, 'The Real Book');
      expect(saved.pendingChange, PendingChange.write);
      expect(collections.hasPendingChanges, isTrue);
    });

    test('a collection survives being read back off the device', () async {
      final store = await LocalStore.inMemory();
      final first =
          CollectionsRepository(store, _OfflineApi(), _SignedIn(store));
      await first.init();
      final saved = await first.saveCollection(title: 'The Real Book');
      await first.saveEntry(saved.id, scoreId: 'score-1');
      await first.saveEntry(saved.id, onPaper: true, description: 'page 62');

      // The same device, opened again.
      final second =
          CollectionsRepository(store, _OfflineApi(), _SignedIn(store));
      await second.init();

      final back = second.getCollection(saved.id)!;
      expect(back.title, 'The Real Book');
      expect(back.entries, hasLength(2));
      expect(back.entries.last.scoreId, isNull,
          reason: 'a piece on paper is still a piece on paper');
      expect(back.pendingEntries, hasLength(2),
          reason: 'what was owed is still owed');
    });

    test('a piece added is queued behind the collection it is in', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');

      final withPiece =
          await collections.saveEntry(collection.id, scoreId: 'score-1');

      expect(withPiece.entries.single.scoreId, 'score-1');
      expect(withPiece.entries.single.synced, isFalse);
      expect(withPiece.pendingEntries.single.action, PendingChange.write);
    });

    test('writing a collection leaves what is in it alone', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      await collections.saveEntry(collection.id, scoreId: 'score-1');

      final renamed = await collections.saveCollection(
          id: collection.id, title: 'The Real Book');

      expect(renamed.title, 'The Real Book');
      expect(renamed.entries.single.scoreId, 'score-1');
    });

    test('a piece taken out again before it was ever sent is simply gone',
        () async {
      // There is no row on the server to remove, so there is nothing to tell
      // it about.
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final added =
          await collections.saveEntry(collection.id, scoreId: 'score-1');

      final removed = await collections.deleteEntry(
          collection.id, added.entries.single.id);

      expect(removed.entries, isEmpty);
      expect(removed.pendingEntries, isEmpty);
    });

    test('a piece that is taken out can be put back in', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final added =
          await collections.saveEntry(collection.id, scoreId: 'score-1');
      await collections.deleteEntry(collection.id, added.entries.single.id);

      final filled =
          await collections.saveEntry(collection.id, scoreId: 'score-1');

      expect(filled.entries, hasLength(1),
          reason: 'the rule is about what is in it now');
    });

    test('a piece already in the collection stays where it is when it is'
        ' written', () async {
      // A collection has no order, so writing a piece is never a move.
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      await collections.saveEntry(collection.id, scoreId: 'a');
      final two = await collections.saveEntry(collection.id, scoreId: 'b');

      final written = await collections.saveEntry(collection.id,
          id: two.entries.first.id, description: 'page 4');

      expect([for (final entry in written.entries) entry.scoreId], ['a', 'b']);
      expect(written.entries.first.description, 'page 4');
    });
  });

  group('a score is in a collection once', () {
    test('and adding it again names the entry it is already in', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final added =
          await collections.saveEntry(collection.id, scoreId: 'score-1');

      await expectLater(
        collections.saveEntry(collection.id, scoreId: 'score-1'),
        throwsA(isA<ScoreAlreadyInCollectionException>().having(
            (error) => error.entryId, 'entryId', added.entries.single.id)),
      );
      expect(collections.getCollection(collection.id)!.entries, hasLength(1));
    });

    test('but the entry it is in can be written without being refused',
        () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final added =
          await collections.saveEntry(collection.id, scoreId: 'score-1');

      final written = await collections.saveEntry(collection.id,
          id: added.entries.single.id, scoreId: 'score-1', transposition: -2);

      expect(written.entries.single.transposition, -2);
    });

    test('and the collections a score is in are the ones that hold it',
        () async {
      final (collections, _) = await _repository(_OfflineApi());
      final holding = await collections.saveCollection(title: 'Holding');
      await collections.saveCollection(title: 'Not holding');
      await collections.saveEntry(holding.id, scoreId: 'score-1');

      expect([for (final c in collections.collectionsWith('score-1')) c.id],
          [holding.id]);
    });
  });

  group('a piece that has yet to be scanned', () {
    test('has no score, and two of them are two pieces', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      await collections.saveEntry(collection.id,
          onPaper: true, description: 'page 12');

      final both = await collections.saveEntry(collection.id,
          onPaper: true, description: 'page 13');

      expect(both.entries, hasLength(2));
      expect(both.entries.every((entry) => entry.scoreId == null), isTrue);
    });

    test('has to be called something', () async {
      // A collection has nowhere for a piece to come, so an unnamed one could
      // never be found, sorted, or told from the next unnamed one.
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');

      await expectLater(
        collections.saveEntry(collection.id, onPaper: true, description: '  '),
        throwsA(isA<ArgumentError>()),
      );
      expect(collections.getCollection(collection.id)!.entries, isEmpty);
      expect(collections.getCollection(collection.id)!.pendingEntries, isEmpty,
          reason: 'it should never have been queued either');
    });

    test('cannot have its name taken away', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final written = await collections.saveEntry(collection.id,
          onPaper: true, description: 'page 12');
      final entryId = written.entries.single.id;

      await expectLater(
        collections.saveEntry(collection.id, id: entryId, description: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(collections.getCollection(collection.id)!.entries.single
          .description, 'page 12');
    });

    test('keeps its name, and stays without a score, when something else'
        ' about it changes', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final written = await collections.saveEntry(collection.id,
          onPaper: true, description: 'page 12');
      final entryId = written.entries.single.id;

      final saved = await collections.saveEntry(collection.id,
          id: entryId, transposition: -2);

      expect(saved.entries.single.description, 'page 12');
      expect(saved.entries.single.transposition, -2);
      expect(saved.entries.single.scoreId, isNull);
    });

    test('goes out as having no score, not as a score called null', () async {
      final api = _WorkingApi();
      final (offline, _) = await _repository(_OfflineApi());
      final collection = await offline.saveCollection(title: 'Book');
      await offline.saveEntry(collection.id,
          onPaper: true, description: 'page 62');

      final online = await _online(offline, api);
      await online.syncWithApi();

      expect(api.entryWrites.single, containsPair('score_id', null));
      expect(online.getCollection(collection.id)!.entries.single.scoreId,
          isNull);
      expect(online.hasPendingChanges, isFalse);
    });
  });

  group('how a player reads a piece', () {
    test('is theirs, and is owed to the server on its own', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final added =
          await collections.saveEntry(collection.id, scoreId: 'score-1');
      final entryId = added.entries.single.id;

      final read = await collections.saveEntryView(collection.id, entryId,
          transposition: 5, hiddenParts: ['P2'], zoom: 1.5);

      expect(read.entries.single.view.transposition, 5);
      expect(read.entries.single.view.hiddenParts, ['P2']);
      expect(read.entries.single.view.zoom, 1.5);
      expect(read.pendingViews, [entryId]);
    });

    test('is written whole, keeping what was not said', () async {
      // Saying only that the key has changed is not saying to draw the piece
      // at the size every other one is drawn at, or to put the parts that are
      // off screen back on it.
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final added =
          await collections.saveEntry(collection.id, scoreId: 'score-1');
      final entryId = added.entries.single.id;
      await collections.saveEntryView(collection.id, entryId,
          hiddenParts: ['P2'], zoom: 2);

      final read = await collections.saveEntryView(collection.id, entryId,
          transposition: 3);

      expect(read.entries.single.view.transposition, 3);
      expect(read.entries.single.view.hiddenParts, ['P2']);
      expect(read.entries.single.view.zoom, 2);
    });

    test('may be written by somebody the collection is only shared with',
        () async {
      final (collections, store) = await _repository(_OfflineApi());
      await store.writeCollections([
        Collection(
          id: 'theirs',
          title: "Somebody else's book",
          isOwner: false,
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          entries: const [
            CollectionEntry(id: 'e1', scoreId: 'score-1', synced: true),
          ],
        ).toJson(),
      ]);
      await collections.init();

      final read = await collections.saveEntryView('theirs', 'e1',
          transposition: 4);

      expect(read.entries.single.view.transposition, 4);
      expect(read.pendingViews, ['e1']);
    });

    test('but what is in the collection is not theirs to change', () async {
      final (collections, store) = await _repository(_OfflineApi());
      await store.writeCollections([
        Collection(
          id: 'theirs',
          title: "Somebody else's book",
          isOwner: false,
          lastChangedAt: DateTime.now(),
        ).toJson(),
      ]);
      await collections.init();

      expect(() => collections.saveEntry('theirs', scoreId: 'score-1'),
          throwsA(isA<StateError>()));
      expect(() => collections.saveCollection(id: 'theirs', title: 'Mine'),
          throwsA(isA<StateError>()));
      expect(() => collections.deleteCollection('theirs'),
          throwsA(isA<StateError>()));
    });

    test('goes with the piece when the piece leaves the collection', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection = await collections.saveCollection(title: 'Book');
      final added =
          await collections.saveEntry(collection.id, scoreId: 'score-1');
      final entryId = added.entries.single.id;
      await collections.saveEntryView(collection.id, entryId, transposition: 3);

      final gone = await collections.deleteEntry(collection.id, entryId);

      expect(gone.pendingViews, isEmpty,
          reason: 'a view of a piece that is not in the book is not owed to'
              ' anybody');
    });
  });

  group('when the server can be reached again', () {
    test('what is owed goes out collection, then pieces, then views',
        () async {
      // Each of them is written against the one before it: an entry against a
      // collection, a view against an entry.
      final api = _WorkingApi();
      final (offline, _) = await _repository(_OfflineApi());
      final collection = await offline.saveCollection(title: 'Book');
      final added = await offline.saveEntry(collection.id, scoreId: 'score-1');
      await offline.saveEntryView(collection.id, added.entries.single.id,
          transposition: 2, zoom: 1.5);

      final online = await _online(offline, api);
      await online.syncWithApi();

      expect(api.calls.where((call) => call != 'list').toList(),
          ['putCollection', 'putEntry', 'putEntryView']);
      expect(api.viewWrites.single, containsPair('zoom', 1.5),
          reason: 'how big it is drawn goes with the rest of the view');
      expect(online.hasPendingChanges, isFalse);
      expect(online.getCollection(collection.id)!.entries.single.synced,
          isTrue);
    });

    test('a piece the server already holds is dropped rather than kept queued',
        () async {
      // Two devices, one book: somebody else put the piece in while this one
      // was offline. The piece is in the collection, which is what was wanted,
      // so this second copy of it goes rather than being asked for over and
      // over.
      final api = _WorkingApi();
      final (offline, _) = await _repository(_OfflineApi());
      final collection = await offline.saveCollection(title: 'Book');
      final written =
          await offline.saveEntry(collection.id, scoreId: 'score-1');
      final mine = written.entries.single.id;

      api.stored[collection.id] = {
        'id': collection.id,
        'title': 'Book',
        'entries': <Map<String, dynamic>>[
          {
            'id': 'somebody-elses-entry',
            'score_id': 'score-1',
            'description': '',
            'transposition': 0,
            'view': {'transposition': 0, 'hidden_parts': <String>[]},
          },
        ],
      };

      final online = await _online(offline, api);
      await online.syncWithApi();

      final now = online.getCollection(collection.id)!;
      expect(now.pendingEntries, isEmpty,
          reason: 'it should not keep being asked for');
      expect(now.entries.where((entry) => entry.id == mine), isEmpty,
          reason: 'the second copy of the piece should be gone');
      expect(online.hasPendingChanges, isFalse);
    });

    test('the copy that stays is read in at once', () async {
      // The collection was synced before, so nothing else this sync sends
      // brings back what the server holds.
      final store = await LocalStore.inMemory();
      await store.writeCollections([
        Collection(
          id: 'book',
          title: 'Book',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      final offline =
          CollectionsRepository(store, _OfflineApi(), _SignedIn(store));
      await offline.init();
      await offline.saveEntry('book', scoreId: 'score-1');

      final api = _WorkingApi()
        ..stored['book'] = {
          'id': 'book',
          'title': 'Book',
          'is_owner': true,
          'entries': <Map<String, dynamic>>[
            {'id': 'somebody-elses-entry', 'score_id': 'score-1'},
          ],
        };
      final online = CollectionsRepository(store, api, _SignedIn(store));
      await online.init();
      await online.syncWithApi();

      expect(online.getCollection('book')!.entries.map((entry) => entry.id),
          ['somebody-elses-entry'],
          reason: 'the piece should not be missing until the next sync');
    });

    test('a dropped copy with a note of its own is said out loud', () async {
      final api = _WorkingApi();
      final (offline, _) = await _repository(_OfflineApi());
      final collection = await offline.saveCollection(title: 'Book');
      await offline.saveEntry(collection.id,
          scoreId: 'score-1', description: 'capo 2');
      api.stored[collection.id] = {
        'id': collection.id,
        'title': 'Book',
        'entries': <Map<String, dynamic>>[
          {'id': 'somebody-elses-entry', 'score_id': 'score-1'},
        ],
      };

      final online = await _online(offline, api);
      final problems = <CollectionSyncProblem>[];
      online.addSyncProblemListener(problems.add);
      await online.syncWithApi();

      expect(problems, hasLength(1));
      expect(problems.single.error.isAlreadyInTheCollection, isTrue);
    });

    test('a collection the server refuses is taken back and reported',
        () async {
      final api = _RefusingApi();
      final (collections, _) = await _repository(api);

      final problems = <CollectionSyncProblem>[];
      collections.addSyncProblemListener(problems.add);

      await collections.saveCollection(title: 'Not mine');

      expect(problems, hasLength(1));
      expect(problems.single.error.errorCode, 'not_collection_owner');
      expect(problems.single.error.isWorthRetrying, isFalse);
      expect(collections.hasPendingChanges, isFalse,
          reason: 'a write the server will never take is not owed forever');
    });

    test('an edit that failed for a reason that may pass stays queued',
        () async {
      final api = _WriteFailsApi();
      final (collections, _) = await _repository(api);

      final saved = await collections.saveCollection(title: 'Book');

      expect(collections.getCollection(saved.id)!.pendingChange,
          PendingChange.write);
    });

    test('a collection that was written here is not overwritten by a sync',
        () async {
      // What is still owed was written after the last thing the server said,
      // so it is the newer of the two and the answer is out of date the moment
      // it arrives.
      final api = _WriteFailsApi();
      final (collections, store) = await _repository(api);
      await store.writeCollections([
        Collection(
          id: 'mine',
          title: 'What I typed',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          pendingChange: PendingChange.write,
        ).toJson(),
      ]);
      await collections.init();

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

      await collections.syncWithApi();

      expect(collections.getCollection('mine')!.title, 'What I typed');
      expect(collections.getCollection('mine')!.pendingChange,
          PendingChange.write);
    });

    test('pieces put in here survive what a sync brings in', () async {
      final api = _WriteFailsApi();
      final (collections, store) = await _repository(api);
      await store.writeCollections([
        Collection(
          id: 'mine',
          title: 'Book',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          entries: const [CollectionEntry(id: 'e1', scoreId: 'here-only')],
          pendingEntries: const [PendingEntry('e1', PendingChange.write)],
        ).toJson(),
      ]);
      await collections.init();

      api.answers = [
        {
          'id': 'mine',
          'title': 'Book, renamed elsewhere',
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

      await collections.syncWithApi();

      final now = collections.getCollection('mine')!;
      expect(now.title, 'Book, renamed elsewhere',
          reason: 'what the collection is was not owed, so the server says it');
      expect(now.entries.any((entry) => entry.scoreId == 'here-only'), isTrue,
          reason: 'the answer cannot know about the piece that is waiting');
      expect(now.entries.any((entry) => entry.scoreId == 'somebody-elses'),
          isTrue,
          reason: 'what another device put in is not asked for again');
    });
  });

  group('the change window', () {
    // The server's clock, an hour behind this device's.
    final serverNow = DateTime.now().toUtc().subtract(const Duration(hours: 1));

    Map<String, dynamic> answer(String id, {String? deletedAt}) => {
          'id': id,
          'title': id,
          'description': '',
          'entries': <Map<String, dynamic>>[],
          'shared_with': <String>[],
          'is_owner': true,
          'last_changed_at': serverNow.toIso8601String(),
          'deleted_at': deletedAt,
        };

    test('asks about everything the first time', () async {
      final api = _WorkingApi();
      final (collections, _) = await _repository(api);

      await collections.syncWithApi();

      final (since, _) = api.windows.single;
      expect(since, isNull);
    });

    test('the next one starts at the newest change the server answered with,'
        ' less the overlap', () async {
      final api = _WorkingApi();
      final (collections, _) = await _repository(api);

      api.answers = [answer('a')];
      await collections.syncWithApi();
      api.answers = [];
      await collections.syncWithApi();

      final (secondSince, _) = api.windows.last;
      expect(secondSince, serverNow.subtract(pullOverlap));
      expect(collections.getCollection('a')!.lastSyncedAt, serverNow);
    });

    test('a collection written outside a pull does not move it', () async {
      final api = _WorkingApi();
      final (collections, _) = await _repository(api);

      api.answers = [answer('a')];
      await collections.syncWithApi();

      api.answers = [];
      final written = await collections.saveCollection(title: 'Written later');
      await collections.syncWithApi();

      final (since, _) = api.windows.last;
      expect(since, serverNow.subtract(pullOverlap));
      expect(collections.getCollection(written.id)!.lastSyncedAt, isNotNull,
          reason: 'the server has it, so a delete has to be sent there');
    });

    test('a collection deleted on the server is kept here as a headstone',
        () async {
      final api = _WorkingApi();
      final (collections, _) = await _repository(api);
      api.answers = [answer('a')];
      await collections.syncWithApi();

      api.answers = [
        answer('a', deletedAt: DateTime.now().toUtc().toIso8601String()),
      ];
      await collections.syncWithApi();

      expect(collections.getCollection('a'), isNull);
      expect(collections.collections, isEmpty);
    });
  });

  group('a collection that is deleted', () {
    test('is kept as a headstone and the server is told', () async {
      final (collections, store) = await _repository(_OfflineApi());
      await store.writeCollections([
        Collection(
          id: 'gone',
          title: 'Last year',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      await collections.init();

      await collections.deleteCollection('gone');

      expect(collections.getCollection('gone'), isNull);
      expect(collections.hasPendingChanges, isTrue,
          reason: 'the server has to be told');
    });

    test('and was never sent is nothing to tell the server about', () async {
      final (collections, _) = await _repository(_OfflineApi());
      final collection =
          await collections.saveCollection(title: 'Typed and thrown away');
      await collections.saveEntry(collection.id, scoreId: 'score-1');

      await collections.deleteCollection(collection.id);

      expect(collections.hasPendingChanges, isFalse);
    });

    test('comes back when it is written again', () async {
      final (collections, store) = await _repository(_OfflineApi());
      await store.writeCollections([
        Collection(
          id: 'gone',
          title: 'Last year',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      await collections.init();
      await collections.deleteCollection('gone');

      final back =
          await collections.saveCollection(id: 'gone', title: 'Back on');

      expect(back.deletedAt, isNull);
      expect(collections.getCollection('gone'), isNotNull);
    });
  });

  test('an address it is shared with is written the way the API reads one',
      () async {
    final (collections, _) = await _repository(_OfflineApi());

    final collection = await collections.saveCollection(
      title: 'Book',
      sharedWith: [
        '  Bas@Example.com ',
        'bas@example.com',
        '',
        'ann@example.com',
      ],
    );

    expect(collection.sharedWith, ['bas@example.com', 'ann@example.com']);
  });

  group('what is written while a push is out', () {
    test('a piece put into a new collection before it is stored stays in it',
        () async {
      // The picker shows up as soon as the collection is kept here, so a piece
      // can be put in while the collection itself is still on its way.
      final api = _HeldApi();
      final (collections, _) = await _repository(api);

      final saving = collections.saveCollection(id: 'book', title: 'Book');
      await pumpEventQueue();
      expect(api.calls, ['putCollection']);

      final adding = collections.saveEntry('book', scoreId: 'score-1');
      await pumpEventQueue();
      api.release();
      await saving;
      await adding;

      final now = collections.getCollection('book')!;
      expect(now.entries.map((entry) => entry.scoreId), ['score-1']);
      expect(now.entries.single.synced, isTrue);
      expect(api.entryWrites, hasLength(1));
      expect(collections.hasPendingChanges, isFalse);
    });
  });

  group('what is sent and what is read back at the same time', () {
    test('edits made one straight after another all stay', () async {
      final (collections, store) = await _repository(_OfflineApi());
      final made = await collections.saveCollection(title: 'Book');
      await collections.saveEntry(made.id, id: 'a', scoreId: 'a');
      await collections.saveEntry(made.id, id: 'b', scoreId: 'b');

      await Future.wait([
        collections.saveEntry(made.id, id: 'a', description: 'page 62'),
        collections.saveEntry(made.id, id: 'b', description: 'red folder'),
        collections.saveCollection(id: made.id, title: 'Book, renamed'),
      ]);

      final reopened =
          CollectionsRepository(store, _OfflineApi(), _SignedIn(store));
      await reopened.init();
      for (final now in [
        collections.getCollection(made.id)!,
        reopened.getCollection(made.id)!,
      ]) {
        expect(now.title, 'Book, renamed');
        expect(now.entries.map((entry) => entry.description),
            ['page 62', 'red folder']);
      }
    });

    test('a pull made before a write and answered after it does not undo it',
        () async {
      final api = _SlowListingApi();
      final store = await LocalStore.inMemory();
      final before = Collection(
        id: 'book',
        title: 'Old title',
        lastChangedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );
      await store.writeCollections([before.toJson()]);
      final collections = CollectionsRepository(store, api, _SignedIn(store));
      await collections.init();

      api.answers = [
        {...before.toJson(), 'is_owner': true, 'entries': <Object?>[]},
      ];
      final syncing = collections.syncWithApi();
      await api.asked.future;
      await collections.saveCollection(id: 'book', title: 'New title');
      api.answer.complete();
      await syncing;

      expect(collections.getCollection('book')!.title, 'New title');
    });

    test('a sync in another tab does not drop a piece put in here meanwhile',
        () async {
      final store = await LocalStore.inMemory();
      final before = Collection(
        id: 'book',
        title: 'Real Book',
        lastChangedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );
      await store.writeCollections([before.toJson()]);
      final api = _SlowListingApi()
        ..answers = [
          {...before.toJson(), 'is_owner': true, 'entries': <Object?>[]},
        ];
      final otherTab = CollectionsRepository(store, api, _SignedIn(store));
      await otherTab.init();
      final thisTab =
          CollectionsRepository(store, _OfflineApi(), _SignedIn(store));
      await thisTab.init();

      final syncing = otherTab.syncWithApi();
      await api.asked.future;
      await thisTab.saveEntry('book', id: 'n', scoreId: 'n');
      api.answer.complete();
      await syncing;

      await thisTab.saveCollection(id: 'book', title: 'Real Book 2');
      expect(thisTab.getCollection('book')!.entries.map((entry) => entry.id),
          ['n']);
      expect(
          thisTab.getCollection('book')!.pendingEntries.map((owed) => owed.id),
          ['n']);
    });

    test('what another tab stored is not sent back over by this one', () async {
      final store = await LocalStore.inMemory();
      await store.writeCollections([
        Collection(
          id: 'book',
          title: 'Before',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      ]);
      final api = _SometimesThereApi();
      final thisTab = CollectionsRepository(store, api, _SignedIn(store));
      await thisTab.init();
      await thisTab.saveCollection(id: 'book', title: 'Offline');

      api.there = true;
      final otherTab = CollectionsRepository(store, api, _SignedIn(store));
      await otherTab.init();
      await otherTab.syncWithApi();
      await otherTab.saveCollection(id: 'book', title: 'Latest');

      await thisTab.syncWithApi();

      expect(api.titlesWritten, ['Offline', 'Latest']);
      expect(thisTab.getCollection('book')!.title, 'Latest');
    });

    test('a write whose token could not be had stays queued', () async {
      final store = await LocalStore.inMemory();
      final collections =
          CollectionsRepository(store, _WorkingApi(), _TokenFails(store));
      await collections.init();

      final saved = await collections.saveCollection(title: 'Book');

      expect(collections.getCollection(saved.id)!.pendingChange,
          PendingChange.write);
    });

    test('a token the API refuses is forgotten, and the write stays queued',
        () async {
      final store = await LocalStore.inMemory();
      final oidc = _Counting(store);
      final collections =
          CollectionsRepository(store, _TokenRefusedApi(), oidc);
      await collections.init();

      final saved = await collections.saveCollection(title: 'Book');

      expect(oidc.forgotten, 1);
      expect(collections.getCollection(saved.id)!.pendingChange,
          PendingChange.write);
    });
  });

  group('what the server refuses', () {
    test('a new collection it refuses is kept with the pieces put into it',
        () async {
      // It was never on the server, so there is nothing there to take it back
      // to: what the player made stays, and its pieces wait for a write of the
      // collection the server will take.
      final (offline, _) = await _repository(_OfflineApi());
      final made =
          await offline.saveCollection(title: 'Book', sharedWith: ['bas']);
      await offline.saveEntry(made.id, scoreId: 'score-1');

      final api = _RefusingApi();
      final online = await _online(offline, api);
      final problems = <CollectionSyncProblem>[];
      online.addSyncProblemListener(problems.add);
      await online.syncWithApi();

      final now = online.getCollection(made.id);
      expect(problems, hasLength(1));
      expect(now, isNotNull, reason: 'a refused write is not a deleted book');
      expect(now!.entries, hasLength(1));
      expect(now.pendingEntries, hasLength(1));
      expect(api.calls, isNot(contains('putEntry')));
    });

    test('a refused collection write keeps the pieces put into it', () async {
      // A mistyped address is the collection's own write. The pieces are
      // separate writes the server has said nothing against.
      final api = _RefusingApi();
      final (collections, store) = await _repository(api);
      api.stored['book'] = {
        'id': 'book',
        'title': 'Book',
        'is_owner': true,
        'entries': <Map<String, dynamic>>[],
      };
      await store.writeCollections([
        Collection(
          id: 'book',
          title: 'Book',
          sharedWith: const ['not an address'],
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          pendingChange: PendingChange.write,
          entries: const [CollectionEntry(id: 'e1', scoreId: 'score-1')],
          pendingEntries: const [PendingEntry('e1', PendingChange.write)],
        ).toJson(),
      ]);
      await collections.init();

      final problems = <CollectionSyncProblem>[];
      collections.addSyncProblemListener(problems.add);
      await collections.syncWithApi();

      final now = collections.getCollection('book')!;
      expect(problems, hasLength(1));
      expect(now.sharedWith, isEmpty, reason: 'the refused write is taken back');
      expect(now.entries.map((entry) => entry.id), ['e1']);
      expect(api.calls, contains('putEntry'));
      expect(collections.hasPendingChanges, isFalse);
    });

    test('a collection that is not there takes what was to go in it with it',
        () async {
      final api = _RefusingApi();
      final (collections, store) = await _repository(api);
      await store.writeCollections([
        Collection(
          id: 'gone',
          title: 'Gone',
          lastChangedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
          pendingChange: PendingChange.write,
          entries: const [CollectionEntry(id: 'e1', scoreId: 'score-1')],
          pendingEntries: const [PendingEntry('e1', PendingChange.write)],
        ).toJson(),
      ]);
      await collections.init();

      final problems = <CollectionSyncProblem>[];
      collections.addSyncProblemListener(problems.add);
      await collections.syncWithApi();

      expect(problems, hasLength(1), reason: 'one problem, not one per piece');
      expect(api.calls, isNot(contains('putEntry')));
      expect(collections.hasPendingChanges, isFalse);
    });
  });
}

/// An API that holds on to the first collection write until it is let go,
/// the way a slow network does, with its answer as it was when the write
/// arrived.
class _HeldApi extends _WorkingApi {
  Completer<void>? _held = Completer<void>();

  void release() => _held?.complete();

  @override
  Future<Map<String, dynamic>> putCollection(
      String collectionId, String token, Map<String, Object?> write) async {
    final answer = {
      ...await super.putCollection(collectionId, token, write),
      'entries': <Map<String, dynamic>>[],
    };
    final held = _held;
    if (held != null) {
      await held.future;
      _held = null;
    }
    return answer;
  }
}

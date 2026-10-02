import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sync/engine.dart';
import 'package:uuid/uuid.dart';

final _log = Logger('Collections');

/// The collections, as this device has them.
///
/// A collection is written here first and sent afterwards, for the same reason
/// a set is: a player adds a piece to the book where the book is, which is
/// where there is no network. How that is done — and what it costs when this
/// device and the server disagree — is the same for a collection as for a set,
/// and is said once, in [SyncEngine].
///
/// The one rule that is a collection's own is that a score is in it at most
/// once. It is held here as well as on the server, because a player who is
/// offline should be told they already have a piece at the moment they add it
/// rather than at the next sync.
class CollectionsRepository extends ChangeNotifier {
  CollectionsRepository(
    LocalStore store,
    CollectionsApi api,
    OidcApi oidc,
  ) {
    _sync = SyncEngine(_Collections(store, api), oidc, notifyListeners);
  }

  static const _uuid = Uuid();

  late final _Engine _sync;

  /// The collections there are, most recently changed first. The deleted ones
  /// are kept but are no longer collections anyone has.
  List<Collection> get collections => _sync.all;

  Collection? getCollection(String collectionId) => _sync.get(collectionId);

  /// The collections a score is in, most recently changed first.
  ///
  /// This is the question a collection exists to answer: a player who has a
  /// piece on screen wants to know which book it came out of and what else is
  /// in that book with it.
  List<Collection> collectionsWith(String scoreId) => [
        for (final collection in collections)
          if (collection.holds(scoreId)) collection,
      ];

  /// Why what is owed about one collection was not synced the last time it was
  /// tried: see [SyncEngine.whyNotSynced].
  Object? whyNotSynced(String id) => _sync.whyNotSynced(id);

  /// Whether anything here is still owed to the server.
  bool get hasPendingChanges => _sync.hasPendingChanges;

  Future<void> init() => _sync.init();

  void addSyncProblemListener(void Function(CollectionSyncProblem) listener) =>
      _sync.addSyncProblemListener(listener);

  void removeSyncProblemListener(
          void Function(CollectionSyncProblem) listener) =>
      _sync.removeSyncProblemListener(listener);

  // -------------------------------------------------------------------------
  // WRITING
  // -------------------------------------------------------------------------

  /// Stores what a collection is — the group of pieces, and who may read it —
  /// and hands it back.
  ///
  /// What is in it is not touched: an entry is written on its own, so
  /// correcting a title is correcting a title. A collection that is created
  /// here is created empty and filled afterwards, the same way it is on the
  /// server.
  ///
  /// A collection that is only shared with this user is not this user's to
  /// change, and writing one is refused rather than queued: there is no moment
  /// later at which the server would take it.
  Future<Collection> saveCollection({
    String? id,
    required String title,
    String description = '',
    List<String> sharedWith = const [],
  }) {
    final collectionId = id ?? _uuid.v4();
    return _sync.save(
      collectionId,
      (existing) => Collection(
        id: collectionId,
        title: title,
        description: description,
        entries: existing?.entries ?? const [],
        sharedWith: addressesOf(sharedWith),
        isOwner: existing?.isOwner ?? true,
        lastChangedAt: DateTime.now(),
        // Nothing is carried over from a deletion, so writing a collection that
        // had been deleted brings it back: a client that still has it and edits
        // it is saying it should exist.
        lastSyncedAt: existing?.lastSyncedAt,
        pendingChange: PendingChange.write,
        pendingViews: existing?.pendingViews ?? const [],
        pendingEntries: existing?.pendingEntries ?? const [],
      ),
    );
  }

  /// Puts one piece into a collection, or changes what the group does with it,
  /// and hands the collection back as it now reads.
  ///
  /// A collection holds a piece once. Adding a score the collection already
  /// has is [ScoreAlreadyInCollectionException], which names the entry it is
  /// already in — the caller wanted the piece to be in the book, and it is, so
  /// what to do with that is the page's to decide rather than a write to make
  /// twice. Writing the entry a score is already in is not that: it is saying
  /// what the group does with a piece that is in the collection.
  ///
  /// The pieces with no score are outside the rule: they are told apart by
  /// what is written next to them, and two lines of a book nobody has scanned
  /// are two pieces. Which is why one of those has to be called something — a
  /// piece with no score and no name cannot be found, sorted, or told from the
  /// next one, so it is refused here rather than queued for a server that will
  /// refuse it too.
  ///
  /// Which piece it is, is only changed when [scoreId] is said at all: leaving
  /// it out keeps the score the entry has, and saying it with [onPaper] makes
  /// the entry a piece that is not in here. Null cannot mean both.
  Future<Collection> saveEntry(
    String collectionId, {
    String? id,
    String? scoreId,
    bool onPaper = false,
    String? description,
    int? transposition,
  }) async {
    await _sync.takeInWhatOthersStored();
    final existing = _sync.owned(collectionId);

    final entryId = id ?? _uuid.v4();
    final known = existing.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    final score =
        onPaper ? null : scoreIdOf(scoreId) ?? known?.scoreId;
    final written = description ?? known?.description ?? '';

    // Only a piece being put in, or an entry being changed to another score,
    // is asked about. An entry that keeps its score is a note or a key being
    // changed on a piece that is in here — and the collection can hold it twice
    // for a while, when two devices put it in offline, which is no reason to
    // refuse a note on either copy.
    if (score != null && score != known?.scoreId) {
      final alreadyIn = existing.entries
          .where((candidate) =>
              candidate.id != entryId && candidate.scoreId == score)
          .firstOrNull;
      if (alreadyIn != null) {
        throw ScoreAlreadyInCollectionException(score, alreadyIn.id);
      }
    }

    if (score == null && written.trim().isEmpty) {
      throw ArgumentError('A piece with no score has nothing to be called by'
          ' but what is written next to it.');
    }

    final entry = CollectionEntry(
      id: entryId,
      scoreId: score,
      description: written,
      transposition: transpositionOf(transposition ?? known?.transposition),
      // How this user reads it is theirs and is written on its own, so an entry
      // that is renamed keeps it.
      view: known?.view ?? const CollectionEntryView(),
      synced: known?.synced ?? false,
    );

    // A piece that is already in the collection stays where it is in the list,
    // and a new one goes on the end. Neither says anything: a collection has no
    // order, and where a page draws a piece is where its title puts it.
    final entries = [
      for (final candidate in existing.entries)
        if (candidate.id == entryId) entry else candidate,
      if (known == null) entry,
    ];

    await _sync.keep([
      _sync.withEntries(
        existing,
        entries,
        owing(existing.pendingEntries, entryId, PendingChange.write),
      )
    ]);
    await _sync.pushIfPossible(collectionId);
    return _sync.held(collectionId)!;
  }

  /// Takes one piece out of a collection.
  ///
  /// What every player said about how they look at it goes with it: it was
  /// about a piece that is no longer in the collection.
  Future<Collection> deleteEntry(String collectionId, String entryId) =>
      _sync.deleteEntry(collectionId, entryId);

  /// Stores how this user looks at one entry, and tells the server as soon as
  /// it can.
  ///
  /// This is not writing the collection, and it is deliberately not asked to
  /// be the owner of one: a view says nothing about the collection and changes
  /// nothing anybody else sees, so a player who cannot add a piece to the book
  /// can still say what key they read one in, which parts they want on screen,
  /// and how big they draw it.
  ///
  /// A view is written whole, so what is not said here is filled in from how
  /// the entry is read now. Saying only that the key has changed is not saying
  /// to draw the piece at the size every other one is drawn at, or to put the
  /// parts that are off screen back on it.
  Future<Collection> saveEntryView(
    String collectionId,
    String entryId, {
    int? transposition,
    List<String>? hiddenParts,
    double? zoom,
  }) =>
      _sync.saveEntryView(
        collectionId,
        entryId,
        transposition: transposition,
        hiddenParts: hiddenParts,
        zoom: zoom,
      );

  /// Marks the collection as deleted here, and tells the server as soon as it
  /// can.
  ///
  /// It is kept rather than dropped, the same way the server keeps it: a sync
  /// only asks about what changed since the last one, so a collection that was
  /// simply forgotten here would be fetched straight back in as something new.
  Future<void> deleteCollection(String collectionId) =>
      _sync.delete(collectionId);

  // -------------------------------------------------------------------------
  // SYNCING
  // -------------------------------------------------------------------------

  /// Squares what is here with what is on the server: what was written here
  /// goes out first, so that a collection that has just been pushed is not
  /// read back as it was before the push, and what the server has changed
  /// since the last sync comes in after.
  Future<void> syncWithApi() => _sync.syncWithApi();

  /// Forgets every collection on this device, what is owed about them included,
  /// for a device that is handed to somebody else.
  Future<void> forgetAll() => _sync.forgetAll();
}

/// The piece is already in the collection.
///
/// It is the one refusal that is worth acting on rather than reporting: what
/// the caller wanted was the piece to be in the book, and it is. What it is in
/// is [entryId], so a page can point at it instead of saying no.
class ScoreAlreadyInCollectionException implements Exception {
  const ScoreAlreadyInCollectionException(
    this.scoreId,
    this.entryId,
  );

  final String scoreId;

  /// The entry the score is already in.
  final String entryId;

  @override
  String toString() =>
      "Score '$scoreId' is already in this collection, as entry '$entryId'.";
}

/// An edit the server refused, which this app has taken back.
///
/// Giving up on an edit is the one thing the app does behind the player's back,
/// so it says so when it happens.
class CollectionSyncProblem {
  const CollectionSyncProblem({
    required this.collectionId,
    required this.title,
    required this.action,
    required this.error,
  });

  final String collectionId;
  final String title;
  final String action;
  final CollectionsApiException error;
}

typedef _Engine = SyncEngine<Collection, CollectionEntry,
    CollectionsApiException, CollectionSyncProblem>;

/// What a collection is to the [SyncEngine]: where it is stored, which
/// endpoints it is written to, and what is done when the server says it
/// already holds a piece.
class _Collections extends SyncAdapter<Collection, CollectionEntry,
    CollectionsApiException, CollectionSyncProblem> {
  _Collections(this._store, this._api);

  final LocalStore _store;
  final CollectionsApi _api;

  @override
  String get noun => 'Collection';

  @override
  Future<List<Map<String, Object?>>> readStored() => _store.readCollections();

  @override
  Future<void> writeStored(List<Map<String, Object?>> records) =>
      _store.writeCollections(records);

  @override
  Future<void> forgetStored() => _store.forgetCollections();

  @override
  Collection fromJson(Map<String, Object?> json) => Collection.fromJson(json);

  @override
  Collection fromApi(Map<String, dynamic> json, DateTime syncedAt) =>
      Collection.fromApi(json, syncedAt);

  @override
  CollectionEntry entryFromApi(Map<String, dynamic> json) =>
      CollectionEntry.fromApi(json);

  @override
  Future<bool> canBeReached() => _api.canBeReached();

  @override
  Future<List<Map<String, dynamic>>> list(
    DateTime? changesSince,
    DateTime changesUntil,
    String token,
  ) =>
      _api.listCollections(changesSince, changesUntil, token);

  @override
  Future<Map<String, dynamic>?> fetch(String id, String token) =>
      _api.getCollection(id, token);

  @override
  Future<Map<String, dynamic>> put(
    String id,
    String token,
    Map<String, Object?> write,
  ) =>
      _api.putCollection(id, token, write);

  @override
  Future<void> remove(String id, String token) =>
      _api.deleteCollection(id, token);

  @override
  Future<Map<String, dynamic>> putEntry(
    String id,
    String entryId,
    String token,
    Map<String, Object?> write,
  ) =>
      _api.putEntry(id, entryId, token, write);

  @override
  Future<void> removeEntry(String id, String entryId, String token) =>
      _api.deleteEntry(id, entryId, token);

  @override
  Future<Map<String, dynamic>> putEntryView(
    String id,
    String entryId,
    String token,
    Map<String, Object?> write,
  ) =>
      _api.putEntryView(id, entryId, token, write);

  @override
  CollectionSyncProblem problem({
    required String id,
    required String title,
    required String action,
    required CollectionsApiException error,
  }) =>
      CollectionSyncProblem(
        collectionId: id,
        title: title,
        action: action,
        error: error,
      );

  @override
  Future<EntryRun<Collection, CollectionEntry, CollectionsApiException>?>
      startEntries(_Engine engine, Collection collection) async => _Pieces(
            engine,
            _api,
            collection.id,
            [...collection.pendingEntries],
            collection.lastChangedAt,
          );
}

/// Sends what has been put into the collection here and what has been taken
/// out, one piece at a time and in the order it was done.
///
/// A piece the collection already holds is not a refusal like the others: see
/// [take].
class _Pieces
    extends EntryRun<Collection, CollectionEntry, CollectionsApiException> {
  _Pieces(
    this._engine,
    this._api,
    this._collectionId,
    this.queue,
    this._lastChangedAtTheStart,
  );

  final _Engine _engine;
  final CollectionsApi _api;
  final String _collectionId;

  /// When the collection itself was last changed as this run started: see
  /// [_takeInTheCopiesKept].
  final DateTime _lastChangedAtTheStart;

  @override
  final List<PendingEntry> queue;

  /// The copies that were dropped for being in the collection already.
  final _dropped = <(CollectionEntry, CollectionsApiException)>[];

  @override
  Map<String, Object?> writeOf(Collection collection, CollectionEntry entry) =>
      {
        // Null is sent as null: it is a piece that is not in here, which the
        // API takes, and not a score it has never heard of.
        'score_id': entry.scoreId,
        'description': entry.description,
        'transposition': entry.transposition,
      };

  @override
  bool takes(CollectionsApiException error) => error.isAlreadyInTheCollection;

  /// The collection already holds the piece. That is somebody having added it
  /// on another device while this one was offline, and the answer is not to
  /// keep asking or to keep two of it: the piece is in the book, which is what
  /// was wanted, so this second copy of it goes and the one that is already
  /// there stays.
  @override
  Future<void> take(PendingEntry owed, CollectionsApiException error) async {
    _log.fine('the collection already holds the score of entry'
        ' ${owed.id}; dropping this copy of it');
    final current = _engine.held(_collectionId)!;
    if (!_engine.isStillOwed(current, owed)) {
      // It was changed again while this was on its way, and that is what goes
      // next.
      return;
    }
    // The copy the server holds may be one this device has taken out, and
    // whose removal has not reached it yet — a piece taken out and put back
    // in offline, with the removal failing for a reason that may pass. That
    // copy is going, so this one is the one that stays: it waits behind the
    // removal rather than being dropped, and nothing of the piece is lost.
    // With no word of which copy the server holds, any removal still owed is
    // taken to be that one.
    final heldAs = error.problem?['entryId'];
    final removalOwed = current.pendingEntries.any((candidate) =>
        candidate.action == PendingChange.delete &&
        (heldAs is! String || candidate.id == heldAs));
    if (removalOwed) {
      _log.fine('the copy of entry ${owed.id} the collection holds is still to'
          ' be taken out; this one waits for that');
      return;
    }
    final copy = current.entries
        .where((candidate) => candidate.id == owed.id)
        .firstOrNull;
    // Kept as an answer: the refusal was a round trip, and another tab may
    // have stored something about this collection since.
    final kept = await _engine.keepAnswer(
      _engine.withEntries(
        current,
        current.entries.where((candidate) => candidate.id != owed.id).toList(),
        withoutOwed(current.pendingEntries, owed.id),
      ),
    );
    if (kept && copy != null) _dropped.add((copy, error));
  }

  @override
  Future<void>? finish() =>
      _dropped.isEmpty ? null : _takeInTheCopiesKept();

  /// Reads the collection back once a piece put in here was dropped for being
  /// in it already (see [take]): the copy that stays is the one another device
  /// put in, which this one has not heard of yet. Until it has, the piece would
  /// be missing here — and could be put in again, to be dropped again.
  ///
  /// A dropped copy that carried a note or a key of its own is said out loud:
  /// what was written on it is not on the copy that stays.
  ///
  /// Only when the collection itself has not been changed since the run
  /// started. A rename, a share or a delete made while the entries were out
  /// is owed, and the answer knows nothing of it: kept, it would put the old
  /// title back and leave nothing owed to send the new one with. The pull that
  /// follows brings the copies in instead.
  Future<void> _takeInTheCopiesKept() async {
    try {
      final token = await _engine.token();
      final before = _engine.held(_collectionId);
      if (token != null &&
          before != null &&
          before.pendingChange == null &&
          before.lastChangedAt == _lastChangedAtTheStart) {
        final fromApi = await _api.getCollection(_collectionId, token);
        final current = _engine.held(_collectionId);
        if (fromApi != null &&
            current != null &&
            !_engine.changedSince(before)) {
          await _engine.keepAnswer(_engine.carryPending(
            Collection.fromApi(fromApi, _engine.syncedOutsideAPull(current)),
            current,
          ));
        }
      }
    } catch (error, stackTrace) {
      // The next sync brings it in instead.
      _log.warning('collection $_collectionId could not be read back', error,
          stackTrace);
    }

    for (final (entry, error) in _dropped) {
      if (entry.description.isEmpty && entry.transposition == 0) continue;
      _engine.reportProblem(CollectionSyncProblem(
        collectionId: _collectionId,
        title: _engine.held(_collectionId)?.title ?? '',
        action: 'the piece was in it already, so the copy with your note or'
            ' key was dropped',
        error: error,
      ));
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:uuid/uuid.dart';

/// The collections, as this device has them.
///
/// A collection is written here first and sent afterwards, for the same reason
/// a set is: a player adds a piece to the book where the book is, which is
/// where there is no network. Every edit is therefore stored locally, marked as
/// owed to the server, and pushed the first time the server can be reached — at
/// the end of the edit if that is right away, and at the next sync otherwise.
///
/// What that costs is that this device and the server can disagree, and the
/// rule for that is: what was written here wins until it has been pushed. A
/// collection with an edit still owed is never overwritten by what a sync
/// brings in, because that edit is the newer of the two by definition.
///
/// The one rule that is a collection's own is that a score is in it at most
/// once. It is held here as well as on the server, because a player who is
/// offline should be told they already have a piece at the moment they add it
/// rather than at the next sync.
class CollectionsRepository extends ChangeNotifier {
  CollectionsRepository(
    this._store,
    this._api,
    this._oidc,
  );

  static const _uuid = Uuid();

  final LocalStore _store;
  final CollectionsApi _api;
  final OidcApi _oidc;

  /// Every collection that is kept here, the deleted ones included.
  final Map<String, Collection> _collections = {};

  final List<void Function(CollectionSyncProblem)> _problemListeners = [];

  /// The push that is out for each collection, if there is one.
  final Map<String, Future<void>> _pushing = {};

  /// The collections there are, most recently changed first. The deleted ones
  /// are kept but are no longer collections anyone has.
  List<Collection> get collections {
    final all = _collections.values
        .where((collection) => collection.deletedAt == null)
        .toList();
    all.sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));
    return all;
  }

  Collection? getCollection(String collectionId) {
    final collection = _collections[collectionId];
    return collection == null || collection.deletedAt != null
        ? null
        : collection;
  }

  /// The collections a score is in, most recently changed first.
  ///
  /// This is the question a collection exists to answer: a player who has a
  /// piece on screen wants to know which book it came out of and what else is
  /// in that book with it.
  List<Collection> collectionsWith(String scoreId) => [
        for (final collection in collections)
          if (collection.holds(scoreId)) collection,
      ];

  /// Whether anything here is still owed to the server.
  bool get hasPendingChanges =>
      _collections.values.any((collection) => collection.owesAnything);

  Future<void> init() async {
    for (final record in await _store.readCollections()) {
      final collection = Collection.fromJson(record);
      _collections[collection.id] = collection;
    }
    notifyListeners();
  }

  void addSyncProblemListener(void Function(CollectionSyncProblem) listener) =>
      _problemListeners.add(listener);

  void removeSyncProblemListener(
          void Function(CollectionSyncProblem) listener) =>
      _problemListeners.remove(listener);

  void _reportProblem(CollectionSyncProblem problem) {
    for (final listener in [..._problemListeners]) {
      listener(problem);
    }
  }

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
  }) async {
    final collectionId = id ?? _uuid.v4();
    final existing = _collections[collectionId];
    if (existing != null && !existing.isOwner) {
      throw StateError("Collection with id '$collectionId' belongs to someone"
          ' else and cannot be changed.');
    }

    final collection = Collection(
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
    );

    await _keep([collection]);
    await _pushIfPossible(collectionId);
    return _collections[collectionId]!;
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
    final existing = _ownedCollection(collectionId);

    final entryId = id ?? _uuid.v4();
    final known = existing.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    final score =
        onPaper ? null : entryScoreIdOf(scoreId) ?? known?.scoreId;
    final written = description ?? known?.description ?? '';

    if (score != null) {
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

    await _keep([
      _withEntries(
        existing,
        entries,
        _owing(existing.pendingEntries, entryId, PendingChange.write),
      )
    ]);
    await _pushIfPossible(collectionId);
    return _collections[collectionId]!;
  }

  /// Takes one piece out of a collection.
  ///
  /// What every player said about how they look at it goes with it: it was
  /// about a piece that is no longer in the collection.
  Future<Collection> deleteEntry(String collectionId, String entryId) async {
    final existing = _ownedCollection(collectionId);
    final entry = existing.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    if (entry == null) {
      return existing;
    }

    // An entry the server never heard of is nothing to tell it about: there is
    // no row there to remove, and whatever was queued about it is about a piece
    // that was never in any book but this one.
    final owing = entry.synced
        ? _owing(existing.pendingEntries, entryId, PendingChange.delete)
        : _withoutOwed(existing.pendingEntries, entryId);

    await _keep([
      _withEntries(
        existing,
        existing.entries.where((candidate) => candidate.id != entryId).toList(),
        owing,
      )
    ]);
    await _pushIfPossible(collectionId);
    return _collections[collectionId]!;
  }

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
  }) async {
    final existing = _collections[collectionId];
    if (existing == null || existing.deletedAt != null) {
      throw StateError(
          "Collection with id '$collectionId' is not on this device.");
    }
    final entry = existing.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    if (entry == null) {
      throw StateError("Collection '$collectionId' has no entry '$entryId'.");
    }

    await _keep([
      _withEntryView(
        existing,
        entryId,
        CollectionEntryView(
          transposition:
              transpositionOf(transposition ?? entry.view.transposition),
          hiddenParts: [...(hiddenParts ?? entry.view.hiddenParts)],
          zoom: zoomOf(zoom ?? entry.view.zoom),
        ),
        owed: true,
      )
    ]);
    await _pushIfPossible(collectionId);
    return _collections[collectionId]!;
  }

  /// Marks the collection as deleted here, and tells the server as soon as it
  /// can.
  ///
  /// It is kept rather than dropped, the same way the server keeps it: a sync
  /// only asks about what changed since the last one, so a collection that was
  /// simply forgotten here would be fetched straight back in as something new.
  Future<void> deleteCollection(String collectionId) async {
    final existing = _collections[collectionId];
    if (existing == null || existing.deletedAt != null) {
      return;
    }
    if (!existing.isOwner) {
      throw StateError("Collection with id '$collectionId' belongs to someone"
          ' else and cannot be deleted.');
    }

    final now = DateTime.now();
    await _keep([
      existing.copyWith(
        lastChangedAt: now,
        deletedAt: now,
        // A collection the server never heard of is nothing to tell it about:
        // there is no row there to mark as gone, and the headstone here is
        // enough.
        pendingChange:
            existing.lastSyncedAt == null ? null : PendingChange.delete,
        clearPendingChange: existing.lastSyncedAt == null,
        // How anybody read a collection that is gone is not worth a request,
        // and neither is what was put into it or taken out of it.
        pendingViews: const [],
        pendingEntries: const [],
      )
    ]);
    await _pushIfPossible(collectionId);
  }

  /// The collection with the given id, when it is this user's to fill.
  Collection _ownedCollection(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null || collection.deletedAt != null) {
      throw StateError(
          "Collection with id '$collectionId' is not on this device.");
    }
    if (!collection.isOwner) {
      throw StateError("Collection with id '$collectionId' belongs to someone"
          ' else and cannot be changed.');
    }
    return collection;
  }

  // -------------------------------------------------------------------------
  // SYNCING
  // -------------------------------------------------------------------------

  /// Squares what is here with what is on the server: what was written here
  /// goes out first, so that a collection that has just been pushed is not
  /// read back as it was before the push, and what the server has changed
  /// since the last sync comes in after.
  Future<void> syncWithApi() async {
    await _pushPending();
    await _pull();
  }

  /// Sends everything that is still owed to the server.
  ///
  /// One collection failing does not stop the others: they are separate writes
  /// and there is no reason one that can be stored should wait for one that
  /// cannot.
  Future<void> _pushPending() async {
    final owing = _collections.values
        .where((collection) => collection.owesAnything)
        .toList();
    for (final collection in owing) {
      await _push(collection.id);
    }
  }

  Future<void> _pushIfPossible(String collectionId) async {
    final collection = _collections[collectionId];
    if (collection == null || !collection.owesAnything) {
      return;
    }
    if (!await _api.canBeReached() || !await _oidc.canBeReached()) {
      debugPrint('the api cannot be reached; what was written stays queued');
      return;
    }
    await _push(collectionId);
  }

  /// Sends what is owed for one collection and squares what is here with the
  /// answer.
  ///
  /// This never throws. A push that failed for a reason that may pass is left
  /// queued for the next sync; one the server will refuse just as firmly next
  /// time is given up on, the collection is read back the way the server has
  /// it, and the problem is reported — an edit that is quietly dropped is worse
  /// than one that is dropped loudly.
  Future<void> _push(String collectionId) async {
    // One push at a time for a collection. Two of them out at once would each
    // square what is here with an answer that knows nothing about the other,
    // and whichever came back last would put back what the first one had
    // already moved past. A push asked for while one is out goes after it, and
    // reads what is owed at that point.
    final previous = _pushing[collectionId] ?? Future<void>.value();
    final next = previous
        .catchError((Object _) {})
        .then((_) => _pushNow(collectionId));
    _pushing[collectionId] = next;
    try {
      await next;
    } finally {
      if (identical(_pushing[collectionId], next)) {
        _pushing.remove(collectionId);
      }
    }
  }

  Future<void> _pushNow(String collectionId) async {
    final collection = _collections[collectionId];
    if (collection == null) {
      return;
    }

    if (collection.pendingChange != null) {
      await _pushCollection(collectionId);
    }
    // In that order, because each of them is written against the one before
    // it: an entry is written against a collection, and a view against an
    // entry. A collection the server has not been told about is nothing to hang
    // an entry off, and an entry it has not been told about is nothing to hang
    // a view off — so whatever did not get through keeps what depends on it
    // queued behind it.
    if (_collections[collectionId]?.pendingChange != null) {
      return;
    }
    await _pushEntries(collectionId);
    await _pushViews(collectionId);
  }

  Future<void> _pushCollection(String collectionId) async {
    final collection = _collections[collectionId];
    if (collection == null) return;
    final action = collection.pendingChange!;

    try {
      final token = await _oidc.getActiveAccessToken();
      if (token == null) return;

      if (action == PendingChange.delete) {
        await _api.deleteCollection(collection.id, token);
        // Written again while the delete was on its way, which brings it back:
        // that write is newer than the delete and is still owed.
        final current = _collections[collectionId]!;
        if (!_changedSince(collection)) {
          await _keep([current.copyWith(clearPendingChange: true)]);
        }
        return;
      }

      final stored = await _api.putCollection(collection.id, token, {
        'title': collection.title,
        'description': collection.description,
        'shared_with': collection.sharedWith,
      });
      final syncedAt = _syncedOutsideAPull(collection);
      final current = _collections[collectionId]!;
      if (_changedSince(collection)) {
        // It was written again, or deleted, while this was on its way. That is
        // newer than the answer and is still owed; all the answer says that is
        // still true is that the server now has the collection.
        await _keep([
          current.copyWith(
            lastSyncedAt: syncedAt,
            pendingChange: current.deletedAt == null
                ? PendingChange.write
                : PendingChange.delete,
          )
        ]);
        return;
      }
      // What comes back is the collection as the server has it, which is the
      // truth about what a collection is — but not about what has been done to
      // it here and not sent yet, which is newer than anything the server can
      // say. That is read from the collection as it is now rather than as it
      // was sent: a piece may have been put in while the request was out.
      await _keep([
        _carryPending(Collection.fromApi(stored, syncedAt), current),
      ]);
    } on CollectionsApiException catch (error) {
      if (error.isWorthRetrying) {
        debugPrint('failed to $action collection ${collection.id}; it stays'
            ' queued: $error');
        return;
      }
      await _giveUpOn(collection, action, error);
    }
  }

  /// Sends what has been put into the collection here and what has been taken
  /// out, one piece at a time and in the order it was done.
  ///
  /// One entry failing stops neither the others nor the views: they are
  /// separate writes about separate pieces.
  Future<void> _pushEntries(String collectionId) async {
    for (final owed in [...?_collections[collectionId]?.pendingEntries]) {
      final collection = _collections[collectionId];
      if (collection == null) return;

      final entry = collection.entries
          .where((candidate) => candidate.id == owed.id)
          .firstOrNull;
      if (owed.action == PendingChange.write && entry == null) {
        // It was taken out again before this ever went; there is nothing left
        // to write.
        await _keep([_withoutPendingEntry(collection, owed.id)]);
        continue;
      }

      try {
        final token = await _oidc.getActiveAccessToken();
        if (token == null) return;

        if (owed.action == PendingChange.delete) {
          await _api.deleteEntry(collectionId, owed.id, token);
          await _keep([_settled(_collections[collectionId]!, owed)]);
          continue;
        }

        final stored = await _api.putEntry(collectionId, owed.id, token, {
          // Null is sent as null: it is a piece that is not in here, which the
          // API takes, and not a score it has never heard of.
          'score_id': entry!.scoreId,
          'description': entry.description,
          'transposition': entry.transposition,
        });
        final current = _collections[collectionId]!;
        final settled = _isStillOwed(current, owed)
            ? _withStoredEntry(current, stored)
            : _writtenBehindAWrite(current, owed.id);
        await _keep([settled]);
      } on CollectionsApiException catch (error) {
        // The collection already holds the piece. That is somebody having added
        // it on another device while this one was offline, and the answer is
        // not to keep asking or to keep two of it: the piece is in the book,
        // which is what was wanted, so this second copy of it goes and the one
        // that is already there stays.
        if (error.isAlreadyInTheCollection) {
          debugPrint('the collection already holds the score of entry'
              ' ${owed.id}; dropping this copy of it');
          final current = _collections[collectionId]!;
          if (!_isStillOwed(current, owed)) {
            // It was changed again while this was on its way, and that is
            // what goes next.
            continue;
          }
          await _keep([
            _withEntries(
              current,
              current.entries
                  .where((candidate) => candidate.id != owed.id)
                  .toList(),
              _withoutOwed(current.pendingEntries, owed.id),
            )
          ]);
          continue;
        }

        if (error.isWorthRetrying) {
          debugPrint('failed to ${owed.action} entry ${owed.id}; it stays'
              ' queued: $error');
          continue;
        }

        final current = _collections[collectionId];
        if (current != null) {
          await _keep([_settled(current, owed)]);
        }
        _reportProblem(CollectionSyncProblem(
          collectionId: collectionId,
          title: current?.title ?? '',
          action: 'entry ${owed.action}',
          error: error,
        ));
      }
    }
  }

  /// Sends how this user reads the entries they have said something about.
  ///
  /// Each entry is its own write, and one that fails stops neither the others
  /// nor the collection it is in: they are separate things said about separate
  /// pieces.
  Future<void> _pushViews(String collectionId) async {
    for (final entryId in [...?_collections[collectionId]?.pendingViews]) {
      final collection = _collections[collectionId];
      if (collection == null) return;
      final entry = collection.entries
          .where((candidate) => candidate.id == entryId)
          .firstOrNull;
      if (entry == null) {
        // The entry is no longer in the collection, so how it was read is not
        // about anything any more.
        await _keep([_withoutPendingView(collection, entryId)]);
        continue;
      }

      // The entry itself is still owed, so the server has nothing to hang this
      // on yet. It waits for the piece, the way the piece waits for the
      // collection.
      if (collection.pendingEntries.any((owed) => owed.id == entryId)) {
        continue;
      }

      try {
        final token = await _oidc.getActiveAccessToken();
        if (token == null) return;

        final stored = await _api.putEntryView(collectionId, entryId, token, {
          'transposition': entry.view.transposition,
          'hidden_parts': entry.view.hiddenParts,
          'zoom': entry.view.zoom,
        });
        final current = _collections[collectionId]!;
        final now = current.entries
            .where((candidate) => candidate.id == entryId)
            .firstOrNull;
        if (now == null || !identical(now.view, entry.view)) {
          // It was looked at differently again while this was on its way, and
          // that is what goes next.
          continue;
        }
        await _keep([
          _withEntryView(
            current,
            entryId,
            CollectionEntryView.fromJson(stored),
            owed: false,
          )
        ]);
      } on CollectionsApiException catch (error) {
        if (error.isWorthRetrying) {
          debugPrint('failed to save the view of entry $entryId; it stays'
              ' queued: $error');
          continue;
        }

        final current = _collections[collectionId];
        if (current != null) {
          await _keep([_withoutPendingView(current, entryId)]);
        }
        _reportProblem(CollectionSyncProblem(
          collectionId: collectionId,
          title: current?.title ?? '',
          action: 'view',
          error: error,
        ));
      }
    }
  }

  /// Takes back an edit the server will not have, and reports it.
  ///
  /// The collection is read back by its id rather than left to the next sync,
  /// which only asks about what changed since the last one and would not cover
  /// one that was last changed before that. When that read fails too, what is
  /// here stays as it was: it is no longer owed to anybody, so it is stale
  /// rather than lost, and any later change to it brings it back in step.
  ///
  /// Only the collection's own write is taken back. The pieces put into it and
  /// the views of them are separate writes the server has not refused, so they
  /// stay owed — unless there is no collection left to put them into. And a
  /// collection that was written again while the refused write was out is
  /// left owing that newer write, which the server has not said anything
  /// about yet.
  Future<void> _giveUpOn(
    Collection collection,
    String action,
    CollectionsApiException error,
  ) async {
    Map<String, dynamic>? fromApi;
    try {
      final token = await _oidc.getActiveAccessToken();
      fromApi =
          token == null ? null : await _api.getCollection(collection.id, token);
    } catch (readError) {
      final current = _collections[collection.id] ?? collection;
      if (!_changedSince(collection)) {
        await _keep([current.copyWith(clearPendingChange: true)]);
      }
      _reportProblem(CollectionSyncProblem(
        collectionId: collection.id,
        title: collection.title,
        action: action,
        error: error,
      ));
      return;
    }

    final current = _collections[collection.id] ?? collection;
    if (fromApi == null) {
      // There is no such collection for this user: whatever was written here
      // is a collection that does not exist, and a headstone is what that
      // looks like. Nothing that was to go into it can go anywhere.
      await _keep([
        current.copyWith(
          deletedAt: current.deletedAt ?? DateTime.now(),
          clearPendingChange: true,
          pendingViews: const [],
          pendingEntries: const [],
        )
      ]);
    } else if (!_changedSince(collection)) {
      await _keep([
        _carryPending(
          Collection.fromApi(fromApi, _syncedOutsideAPull(collection)),
          current,
        )
      ]);
    }

    _reportProblem(CollectionSyncProblem(
      collectionId: collection.id,
      title: collection.title,
      action: action,
      error: error,
    ));
  }

  /// Reads in everything that changed on the server since the last time it
  /// said anything, the collections that were deleted there included.
  Future<void> _pull() async {
    final token = await _oidc.getActiveAccessToken();
    if (token == null) return;

    // The end of the window is what is recorded as synced, and not the moment
    // the answer arrives: a collection that changed while the request was on
    // its way is not in this answer, and has to be in the next one.
    final syncedAt = DateTime.now();
    final fromApi = await _api.listCollections(
        _lastSyncedAt()?.subtract(pullOverlap), syncedAt, token);
    if (fromApi.isEmpty) {
      return;
    }

    final toStore = <Collection>[];
    for (final json in fromApi) {
      final existing = _collections['${json['id']}'];
      // What has been written here and not sent yet was written after the last
      // thing the server told us, so it is the newer of the two and is kept on
      // top of the answer; the rest of what the server says is taken as it
      // stands. That goes for the pieces in a collection whose own write is
      // still owed too: skipping the answer whole would move the window past
      // what other devices put into it, and it would never be asked for again.
      final carried =
          _carryPending(Collection.fromApi(json, syncedAt), existing);
      toStore.add(existing?.pendingChange == null
          ? carried
          : carried.copyWith(
              title: existing!.title,
              description: existing.description,
              sharedWith: existing.sharedWith,
              lastChangedAt: existing.lastChangedAt,
              deletedAt: existing.deletedAt,
              clearDeletedAt: existing.deletedAt == null,
              pendingChange: existing.pendingChange,
            ));
    }

    await _keep(toStore);
  }

  /// The last moment the server said anything about a collection, which is
  /// where the next change window starts.
  DateTime? _lastSyncedAt() {
    DateTime? latest;
    for (final collection in _collections.values) {
      final synced = collection.lastSyncedAt;
      if (synced != null && (latest == null || synced.isAfter(latest))) {
        latest = synced;
      }
    }
    return latest;
  }

  /// What a collection that was read by itself, rather than listed in a pull,
  /// records as synced.
  ///
  /// It must not move the watermark: another collection may have changed since
  /// the last pull, and a later moment here would make the next pull skip it.
  /// But it cannot stay empty either, because an empty one means the server has
  /// never heard of the collection, and one like that is deleted without
  /// asking.
  DateTime _syncedOutsideAPull(Collection collection) =>
      collection.lastSyncedAt ?? _lastSyncedAt() ?? DateTime.utc(1970);

  /// Whether the collection itself was written or deleted here since [sent]
  /// was read, which a push has to know once its answer is in: the request
  /// was out for a while, and the player did not stop in the meantime.
  bool _changedSince(Collection sent) =>
      _collections[sent.id]?.lastChangedAt != sent.lastChangedAt;

  Future<void> _keep(List<Collection> collections) async {
    if (collections.isEmpty) {
      return;
    }
    for (final collection in collections) {
      _collections[collection.id] = collection;
    }
    await _store.writeCollections(
        [for (final collection in collections) collection.toJson()]);
    notifyListeners();
  }
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

// ---------------------------------------------------------------------------
// PUTTING A COLLECTION BACK TOGETHER
// ---------------------------------------------------------------------------

/// The collection the server just described, with what this device has written
/// and not sent put back on top of it.
///
/// Anything still owed was written after the last thing the server said about
/// it, so it is the newer of the two. That is what is in the collection as a
/// whole while a piece is waiting to be sent — the answer cannot know about the
/// piece — and the view of any entry that is waiting.
Collection _carryPending(Collection incoming, Collection? existing) {
  if (existing == null) {
    return incoming;
  }

  final owedEntries = existing.pendingEntries;
  final entries = _mergedEntries(
    incoming.entries,
    existing.entries,
    owedEntries,
  );
  final owedViews = _keptOf(existing.pendingViews, entries);

  return incoming.copyWith(
    entries: [
      for (final entry in entries)
        if (!owedViews.contains(entry.id))
          entry
        else
          entry.copyWith(
            view: existing.entries
                    .where((candidate) => candidate.id == entry.id)
                    .firstOrNull
                    ?.view ??
                entry.view,
          ),
    ],
    pendingViews: owedViews,
    pendingEntries: owedEntries,
  );
}

/// The pieces the server says are in a collection, with the ones that are owed
/// to it as this device has them.
///
/// Only those are taken from here. The rest is the server's, and that includes
/// whatever another device put in or took out: keeping this device's list
/// whole while one piece is owed would lose that for good, since the next sync
/// only asks about what changed after this one. A piece that is owed goes back
/// in at the place it has here, which is as close as a list that has changed
/// underneath it can come to where it was put.
List<CollectionEntry> _mergedEntries(
  List<CollectionEntry> incoming,
  List<CollectionEntry> existing,
  List<PendingEntry> owed,
) {
  if (owed.isEmpty) {
    return incoming;
  }
  final owedIds = {for (final entry in owed) entry.id};
  final merged = [
    for (final entry in incoming)
      if (!owedIds.contains(entry.id)) entry,
  ];
  for (final (index, entry) in existing.indexed) {
    if (owedIds.contains(entry.id)) {
      merged.insert(index.clamp(0, merged.length), entry);
    }
  }
  return merged;
}

/// The same collection holding different pieces, and with a different idea of
/// what is owed about them.
Collection _withEntries(
  Collection collection,
  List<CollectionEntry> entries,
  List<PendingEntry> pendingEntries,
) =>
    collection.copyWith(
      entries: entries,
      pendingViews: _keptOf(collection.pendingViews, entries),
      pendingEntries: pendingEntries,
    );

/// The same collection with one entry as the server now has it, and nothing
/// left owed about that entry.
///
/// Where it sits in the list is where it already was: a collection has no
/// order, so there is nothing for the server to have moved.
Collection _withStoredEntry(Collection collection, Map<String, dynamic> json) {
  var stored = CollectionEntry.fromApi(json);

  // Its own view is the one this device has: the answer carries the view the
  // server knew about, which is older than one that is still waiting to be
  // sent.
  final here = collection.entries
      .where((entry) => entry.id == stored.id)
      .firstOrNull;
  if (here != null && collection.pendingViews.contains(stored.id)) {
    stored = stored.copyWith(view: here.view);
  }

  final entries = [
    for (final entry in collection.entries)
      if (entry.id == stored.id) stored else entry,
    if (here == null) stored,
  ];

  return _withEntries(
    collection,
    entries,
    _withoutOwed(collection.pendingEntries, stored.id),
  );
}

Collection _withoutPendingEntry(Collection collection, String entryId) =>
    _withEntries(collection, collection.entries,
        _withoutOwed(collection.pendingEntries, entryId));

/// Whether [owed] is still what is owed about its entry, rather than something
/// said about the entry since. Every edit queues a new one, so a write that was
/// out while the entry was edited again is not the one still in the queue.
bool _isStillOwed(Collection collection, PendingEntry owed) =>
    collection.pendingEntries.any((candidate) => identical(candidate, owed));

/// The same collection with [owed] no longer owed, and anything said about the
/// entry since it went out still owed.
Collection _settled(Collection collection, PendingEntry owed) => _withEntries(
      collection,
      collection.entries,
      collection.pendingEntries
          .where((candidate) => !identical(candidate, owed))
          .toList(),
    );

/// The same collection once the server has taken an entry that was changed
/// again here while it was on its way.
///
/// What is here is newer and stays owed; the answer only says that the server
/// has the entry now. So an entry that was taken out in the meantime, which
/// was dropped as one the server had never heard of, has to be taken out
/// there too.
Collection _writtenBehindAWrite(Collection collection, String entryId) {
  final here = collection.entries
      .where((entry) => entry.id == entryId)
      .firstOrNull;
  if (here != null) {
    return collection.copyWith(entries: [
      for (final entry in collection.entries)
        if (entry.id == entryId) entry.copyWith(synced: true) else entry,
    ]);
  }
  if (collection.pendingEntries.any((owed) => owed.id == entryId)) {
    return collection;
  }
  return collection.copyWith(
    pendingEntries:
        _owing(collection.pendingEntries, entryId, PendingChange.delete),
  );
}

/// What is owed about the entries of a collection, with one entry now owing
/// this.
///
/// An entry is owed once however often it is written: what goes out is the
/// entry as it now reads, not every edit that was made to it. The last thing
/// said about it is what is said, so a write that follows a delete replaces it.
List<PendingEntry> _owing(
        List<PendingEntry> owed, String entryId, String action) =>
    [..._withoutOwed(owed, entryId), PendingEntry(entryId, action)];

List<PendingEntry> _withoutOwed(List<PendingEntry> owed, String entryId) =>
    owed.where((entry) => entry.id != entryId).toList();

/// The same collection with one entry looked at differently, and that entry
/// marked as owed to the server or no longer owed.
Collection _withEntryView(
  Collection collection,
  String entryId,
  CollectionEntryView view, {
  required bool owed,
}) {
  final pending =
      collection.pendingViews.where((id) => id != entryId).toList();
  if (owed) {
    pending.add(entryId);
  }

  return collection.copyWith(
    entries: [
      for (final entry in collection.entries)
        if (entry.id != entryId) entry else entry.copyWith(view: view),
    ],
    pendingViews: pending,
  );
}

Collection _withoutPendingView(Collection collection, String entryId) =>
    collection.copyWith(
      pendingViews:
          collection.pendingViews.where((id) => id != entryId).toList(),
    );

/// The entry ids of [owed] that the given entries still have. A view of an
/// entry that is no longer in the collection is about a piece that is no
/// longer in it.
List<String> _keptOf(List<String> owed, List<CollectionEntry> entries) {
  if (owed.isEmpty) {
    return const [];
  }
  return owed.where((id) => entries.any((entry) => entry.id == id)).toList();
}

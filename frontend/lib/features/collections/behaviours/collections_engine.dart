import 'package:logging/logging.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_store.dart';
import 'package:score/features/sync/behaviours/sync_engine.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
import 'package:score/storage/api_exception.dart';

/// The collections, as this device keeps them and the server is told about
/// them.
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
/// rather than at the next sync: see [SaveCollectionEntry].
typedef CollectionsEngine =
    SyncEngine<Collection, CollectionEntry, CollectionSyncProblem>;

/// What a collection is to the [SyncEngine]: where it is stored, which
/// endpoints it is written to, and what is done when the server says it
/// already holds a piece.
class CollectionsAdapter({
  required final Logger logger,
  required final CollectionsStore store,

  /// Where why one was not sent is kept.
  required final SyncHoldsStore holds,
  required final CollectionsApi api,
}) extends SyncAdapter<Collection, CollectionEntry, CollectionSyncProblem> {
  @override
  String get noun => 'Collection';

  @override
  Future<List<Collection>> readStored() => store.getAll();

  @override
  Future<void> writeStored(List<Collection> records) => store.putAll(records);

  @override
  Future<void> forgetStored() => store.removeAll();

  @override
  Future<void> writeWhyNotSynced(String id, WhyNotSynced? why) =>
      holds.write(syncHoldKind, id, why?.toJson());

  @override
  Future<void> forgetWhyNotSynced() => holds.forget(syncHoldKind);

  /// What the store keeps why a collection was not sent under.
  static const syncHoldKind = 'collection';

  @override
  Future<bool> canBeReached() => api.canBeReached();

  @override
  Future<List<Collection>> list(
    DateTime? changesSince,
    DateTime changesUntil,
  ) => api.listCollections(changesSince, changesUntil);

  @override
  Future<Collection?> fetch(String id) => api.getCollection(id);

  @override
  Future<Collection> put(
    String id,
    Map<String, Object?> write,
  ) => api.putCollection(id, write);

  @override
  Future<void> remove(String id) => api.deleteCollection(id);

  @override
  Future<({CollectionEntry entry, int? position})> putEntry(
    String id,
    String entryId,
    Map<String, Object?> write,
  ) async => (
    entry: await api.putEntry(id, entryId, write),
    // A collection's pieces have no running order.
    position: null,
  );

  @override
  Future<void> removeEntry(String id, String entryId) =>
      api.deleteEntry(id, entryId);

  @override
  Future<EntryView> putEntryView(
    String id,
    String entryId,
    Map<String, Object?> write,
  ) => api.putEntryView(id, entryId, write);

  @override
  CollectionSyncProblem problem({
    required String id,
    required String title,
    required String action,
    required ApiException error,
  }) => CollectionSyncProblem(
    collectionId: id,
    title: title,
    action: action,
    error: error,
  );

  @override
  Future<EntryRun<Collection, CollectionEntry>?> startEntries(
    CollectionsEngine engine,
    Collection collection,
  ) async => _Pieces(
    logger: logger,
    engine: engine,
    api: api,
    collectionId: collection.id,
    queue: [...collection.pendingEntries],
    lastChangedAtTheStart: collection.lastChangedAt,
  );
}

/// Sends what has been put into the collection here and what has been taken
/// out, one piece at a time and in the order it was done.
///
/// A piece the collection already holds is not a refusal like the others: see
/// [take].
class _Pieces({
  required final Logger logger,
  required final CollectionsEngine engine,
  required final CollectionsApi api,
  required final String collectionId,
  @override required final List<PendingEntry> queue,

  /// When the collection itself was last changed as this run started: see
  /// [_takeInTheCopiesKept].
  required final DateTime lastChangedAtTheStart,
}) extends EntryRun<Collection, CollectionEntry> {
  /// The copies that were dropped for being in the collection already.
  final _dropped = <(CollectionEntry, ApiException)>[];

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
  bool takes(ApiException error) => error.isAlreadyInTheCollection;

  /// The collection already holds the piece. That is somebody having added it
  /// on another device while this one was offline, and the answer is not to
  /// keep asking or to keep two of it: the piece is in the book, which is what
  /// was wanted, so this second copy of it goes and the one that is already
  /// there stays.
  @override
  Future<void> take(PendingEntry owed, ApiException error) async {
    logger.fine(
      'the collection already holds the score of entry'
      ' ${owed.id}; dropping this copy of it',
    );
    final current = engine.held(collectionId)!;
    if (!engine.isStillOwed(current, owed)) {
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
    final heldAs = error.problem?.entryId;
    final removalOwed = current.pendingEntries.any(
      (candidate) =>
          candidate.action == PendingChange.delete &&
          (heldAs == null || candidate.id == heldAs),
    );
    if (removalOwed) {
      logger.fine(
        'the copy of entry ${owed.id} the collection holds is still'
        ' to be taken out; this one waits for that',
      );
      return;
    }
    final copy = current.entries
        .where((candidate) => candidate.id == owed.id)
        .firstOrNull;
    // Kept as an answer: the refusal was a round trip, and another tab may
    // have stored something about this collection since.
    final kept = await engine.keepAnswer(
      engine.withEntries(
        current,
        current.entries.where((candidate) => candidate.id != owed.id).toList(),
        withoutOwed(current.pendingEntries, owed.id),
      ),
    );
    if (kept && copy != null) _dropped.add((copy, error));
  }

  @override
  Future<void>? finish() => _dropped.isEmpty ? null : _takeInTheCopiesKept();

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
      final before = engine.held(collectionId);
      if (before != null &&
          before.pendingChange == null &&
          before.lastChangedAt == lastChangedAtTheStart) {
        final fromApi = await api.getCollection(collectionId);
        final current = engine.held(collectionId);
        if (fromApi != null &&
            current != null &&
            !engine.changedSince(before)) {
          await engine.keepAnswer(
            engine.carryPending(
              fromApi.copyWith(
                lastSyncedAt: engine.syncedOutsideAPull(current),
              ),
              current,
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      // The next sync brings it in instead.
      logger.warning(
        'collection $collectionId could not be read back',
        error,
        stackTrace,
      );
    }

    for (final (entry, error) in _dropped) {
      if (entry.description.isEmpty && entry.transposition == 0) continue;
      engine.reportProblem(
        CollectionSyncProblem(
          collectionId: collectionId,
          title: engine.held(collectionId)?.title ?? '',
          action:
              'the piece was in it already, so the copy with your note or'
              ' key was dropped',
          error: error,
        ),
      );
    }
  }
}

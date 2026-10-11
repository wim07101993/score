import 'package:logging/logging.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_store.dart';
import 'package:score/features/sync/behaviours/sync_engine.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
import 'package:score/storage/api_exception.dart';

/// The sets, as this device keeps them and the server is told about them.
///
/// A set is written here first and sent afterwards. That is not a nicety: a set
/// is a playlist for a gig, and a gig is where there is no network, so a write
/// that could only be made online is a write that could not be made when it was
/// needed. How that is done — and what it costs when this device and the server
/// disagree — is the same for a set as for a collection, and is said once, in
/// [SyncEngine].
///
/// What is a set's own is its running order: where each song is placed, here
/// and on the server, which is what [SaveSetEntry] and the way the songs are
/// sent (see [_RunningOrder]) are about.
typedef SetsEngine = SyncEngine<ScoreSet, SetEntry, SyncProblem>;

/// What a set is to the [SyncEngine]: where it is stored, which endpoints it
/// is written to, and that its songs are sent in their running order.
class SetsAdapter({
  required final Logger logger,
  required final SetsStore store,

  /// Where why one was not sent is kept.
  required final SyncHoldsStore holds,
  required final SetsApi api,
}) extends SyncAdapter<ScoreSet, SetEntry, SyncProblem> {
  @override
  String get noun => 'Set';

  @override
  Future<List<ScoreSet>> readStored() => store.getAll();

  @override
  Future<void> writeStored(List<ScoreSet> records) => store.putAll(records);

  @override
  Future<void> forgetStored() => store.removeAll();

  @override
  Future<void> writeWhyNotSynced(String id, WhyNotSynced? why) =>
      holds.write(syncHoldKind, id, why?.toJson());

  @override
  Future<void> forgetWhyNotSynced() => holds.forget(syncHoldKind);

  /// What the store keeps why a set was not sent under.
  static const syncHoldKind = 'set';

  @override
  Future<bool> canBeReached() => api.canBeReached();

  @override
  Future<List<ScoreSet>> list(
    DateTime? changesSince,
    DateTime changesUntil,
  ) => api.listSets(changesSince, changesUntil);

  @override
  Future<ScoreSet?> fetch(String id) => api.getSet(id);

  @override
  Future<ScoreSet> put(
    String id,
    Map<String, Object?> write,
  ) => api.putSet(id, write);

  @override
  Future<void> remove(String id) => api.deleteSet(id);

  @override
  Future<({SetEntry entry, int? position})> putEntry(
    String id,
    String entryId,
    Map<String, Object?> write,
  ) => api.putEntry(id, entryId, write);

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
  SyncProblem problem({
    required String id,
    required String title,
    required String action,
    required ApiException error,
  }) => SyncProblem(setId: id, title: title, action: action, error: error);

  @override
  Future<EntryRun<ScoreSet, SetEntry>?> startEntries(
    SetsEngine engine,
    ScoreSet set,
  ) async {
    final queued = _inTheOrderToSend(set);
    final known = await _orderOnTheServer(engine, set, queued);
    if (known == null) return null;
    return _RunningOrder(queue: queued, order: known);
  }

  /// The running order the server has for the set, as the ids of its songs.
  ///
  /// Asked for whenever a song is written, however few are owed: every write
  /// says where the song goes, a note or a key included, and a place counted
  /// in the order this device last heard of puts it wherever another device
  /// has moved the songs around it since. Only removals, which say nothing
  /// about a place, are sent without asking. Null when the set could not be
  /// read, which leaves its songs queued for the next sync.
  Future<List<String>?> _orderOnTheServer(
    SetsEngine engine,
    ScoreSet set,
    List<PendingEntry> queued,
  ) async {
    final here = [
      for (final entry in set.entries)
        if (entry.synced) entry.id,
    ];
    if (queued.every((owed) => owed.action == PendingChange.delete)) {
      return here;
    }

    try {
      final onTheServer = await api.getSet(set.id);
      if (onTheServer == null) {
        // Not there for this user any more: each write will say so.
        return here;
      }
      return onTheServer.entries
          .map((entry) => entry.id)
          .toList(growable: false);
    } catch (error, stackTrace) {
      logger.warning(
        'the running order of set ${set.id} could not be read; what is owed'
        ' about its songs stays queued',
        error,
        stackTrace,
      );
      return null;
    }
  }
}

/// Sends what has been done to the running order here, one song at a time:
/// the removals first, then the songs written in the order they now run in
/// here (see [_inTheOrderToSend]).
///
/// A song is placed on the server just behind the song it comes after here,
/// counted in the running order the server has at the moment the song
/// arrives: the songs sent before it have moved things, and a song whose
/// removal is still to be sent is still in the server's order. Counting its
/// place among the songs here instead puts it wherever an earlier write in
/// the queue changed what is ahead of it — the order arranged offline, then,
/// is not the order the band gets.
///
/// Where a song ends up here once the server has it is where it already is:
/// the place the server answers with is only used to follow the server's
/// order for the songs that are still to go.
class _RunningOrder({
  @override required final List<PendingEntry> queue,

  /// The server's running order, as it is after what was sent so far.
  required var List<String> order,
}) extends EntryRun<ScoreSet, SetEntry> {
  /// Where the song that was written last was asked to go.
  int _position = 0;

  @override
  Map<String, Object?> writeOf(ScoreSet set, SetEntry entry) {
    _position = _placeAfter(order, set.entries, entry);
    return {
      'score_id': entry.scoreId,
      'description': entry.description,
      'transposition': entry.transposition,
      'position': _position,
    };
  }

  @override
  void removed(String entryId) => order = [
    for (final id in order)
      if (id != entryId) id,
  ];

  @override
  void written(String entryId, int? position) {
    order = _placedAt(order, entryId, position ?? _position);
  }
}

/// What is owed about the songs of [set], in the order it is sent in.
///
/// Not the order it was done in. A song is placed behind the song it comes
/// after here, and that is only where it belongs once that song is in its own
/// place: a song put at the end and then another moved in front of it would
/// otherwise be placed behind where the moved one used to be, and stay there
/// once it had moved. Sent in the order the songs run in here, every song ahead
/// of the one being placed has been placed already. The removals go first,
/// since nothing is placed behind a song that is gone; each song is owed once
/// (see [owing]), so no removal is sent after a write of the same song.
List<PendingEntry> _inTheOrderToSend(ScoreSet set) {
  final place = {
    for (final (index, entry) in set.entries.indexed) entry.id: index,
  };
  return [
    for (final owed in set.pendingEntries)
      if (owed.action == PendingChange.delete) owed,
    ...[
      for (final owed in set.pendingEntries)
        if (owed.action != PendingChange.delete) owed,
    ]..sort((a, b) => (place[a.id] ?? -1).compareTo(place[b.id] ?? -1)),
  ];
}

/// Where [entry] goes in the server's running [order] for it to come after
/// the song it comes after here: just behind the nearest song ahead of it here
/// that the server has, and first when there is none.
///
/// Placing it behind a song rather than at a count of songs is what keeps it
/// right whatever else is still to arrive: a song whose removal is still owed,
/// or one that is still to be moved, is in the server's order and not here.
int _placeAfter(List<String> order, List<SetEntry> entries, SetEntry entry) {
  final others = [
    for (final id in order)
      if (id != entry.id) id,
  ];
  for (var index = entries.indexOf(entry) - 1; index >= 0; index--) {
    final at = others.indexOf(entries[index].id);
    if (at >= 0) return at + 1;
  }
  return 0;
}

/// The server's running [order] once [entryId] has been written at
/// [position]: taken out of wherever it was and put back there — at the end
/// when that is beyond it, the way the server does it.
List<String> _placedAt(List<String> order, String entryId, int position) {
  final others = [
    for (final id in order)
      if (id != entryId) id,
  ];
  final at = position.clamp(0, others.length);
  return [...others.sublist(0, at), entryId, ...others.sublist(at)];
}

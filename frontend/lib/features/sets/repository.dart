import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sync/engine.dart';
import 'package:uuid/uuid.dart';

final _log = Logger('Sets');

/// The sets, as this device has them.
///
/// A set is written here first and sent afterwards. That is not a nicety: a set
/// is a playlist for a gig, and a gig is where there is no network, so a write
/// that could only be made online is a write that could not be made when it was
/// needed. How that is done — and what it costs when this device and the server
/// disagree — is the same for a set as for a collection, and is said once, in
/// [SyncEngine].
///
/// What is a set's own is its running order: where each song is placed, here
/// and on the server, which is what [saveEntry] and the way the songs are sent
/// (see [_RunningOrder]) are about.
class SetsRepository extends ChangeNotifier {
  SetsRepository(
    LocalStore store,
    SetsApi api,
    OidcApi oidc,
  ) {
    _sync = SyncEngine(_Sets(store, api), oidc, notifyListeners);
  }

  static const _uuid = Uuid();

  late final SyncEngine<ScoreSet, SetEntry, SetsApiException, SyncProblem>
      _sync;

  /// The sets there are, most recently changed first. The deleted ones are kept
  /// but are no longer sets anyone has.
  List<ScoreSet> get sets => _sync.all;

  ScoreSet? getSet(String setId) => _sync.get(setId);

  /// Why what is owed about one set was not synced the last time it was
  /// tried: see [SyncEngine.whyNotSynced].
  Object? whyNotSynced(String id) => _sync.whyNotSynced(id);

  /// Whether anything here is still owed to the server.
  bool get hasPendingChanges => _sync.hasPendingChanges;

  Future<void> init() => _sync.init();

  void addSyncProblemListener(void Function(SyncProblem) listener) =>
      _sync.addSyncProblemListener(listener);

  void removeSyncProblemListener(void Function(SyncProblem) listener) =>
      _sync.removeSyncProblemListener(listener);

  // -------------------------------------------------------------------------
  // WRITING
  // -------------------------------------------------------------------------

  /// Stores what a set is — the gig, and who may read it — and hands it back.
  ///
  /// What is played in it is not touched: an entry is written on its own, so
  /// correcting a title is correcting a title.
  ///
  /// A set that is only shared with this user is not this user's to change, and
  /// writing one is refused rather than queued: there is no moment later at
  /// which the server would take it.
  Future<ScoreSet> saveSet({
    String? id,
    required String title,
    String description = '',
    List<String> sharedWith = const [],
  }) {
    final setId = id ?? _uuid.v4();
    return _sync.save(
      setId,
      (existing) => ScoreSet(
        id: setId,
        title: title,
        description: description,
        entries: existing?.entries ?? const [],
        sharedWith: addressesOf(sharedWith),
        isOwner: existing?.isOwner ?? true,
        lastChangedAt: DateTime.now(),
        // Nothing is carried over from a deletion, so writing a set that had
        // been deleted brings it back: a client that still has it and edits it
        // is saying it should exist.
        lastSyncedAt: existing?.lastSyncedAt,
        pendingChange: PendingChange.write,
        pendingViews: existing?.pendingViews ?? const [],
        pendingEntries: existing?.pendingEntries ?? const [],
      ),
    );
  }

  /// Puts one score into a set, or changes how it is played, and hands the set
  /// back as it now reads.
  ///
  /// The set is closed up around it: an entry written at a place the set
  /// already has an entry in puts that one and everything after it back by one,
  /// and an entry that is already in the set and is written at another place
  /// moves there. A place beyond the end of the set is the end of the set. No
  /// place at all leaves an entry that is already in the set where it is — a
  /// note or a key is written without one — and puts a new one at the end.
  Future<ScoreSet> saveEntry(
    String setId, {
    String? id,
    String? scoreId,
    String? description,
    int? transposition,
    int? position,
  }) async {
    await _sync.takeInWhatOthersStored();
    final existing = _sync.owned(setId);

    final entryId = id ?? _uuid.v4();
    final known =
        existing.entries.where((entry) => entry.id == entryId).firstOrNull;

    final written = SetEntry(
      id: entryId,
      scoreId: scoreIdOf(scoreId) ?? known?.scoreId,
      description: description ?? known?.description ?? '',
      transposition: transpositionOf(transposition ?? known?.transposition),
      // How this user reads it is theirs and is written on its own, so an entry
      // that is moved or renamed keeps it.
      view: known?.view ?? const EntryView(),
      synced: known?.synced ?? false,
    );

    final others =
        existing.entries.where((entry) => entry.id != entryId).toList();
    // Where it already is, unless it is being moved: taking "no place" for the
    // end would send a song to the back of the gig — for everyone it is shared
    // with — because somebody corrected its note.
    final here = existing.entries.indexWhere((entry) => entry.id == entryId);
    final at = (position ?? (here < 0 ? others.length : here))
        .clamp(0, others.length);

    await _sync.keep([
      _sync.withEntries(
        existing,
        [...others.sublist(0, at), written, ...others.sublist(at)],
        owing(existing.pendingEntries, entryId, PendingChange.write),
      )
    ]);
    await _sync.pushIfPossible(setId);
    return _sync.held(setId)!;
  }

  /// Takes one score out of a set and closes the running order up around it.
  ///
  /// What every player said about how they look at it goes with it: it was
  /// about a song that is no longer played.
  Future<ScoreSet> deleteEntry(String setId, String entryId) =>
      _sync.deleteEntry(setId, entryId);

  /// Stores how this user looks at one entry, and tells the server as soon as
  /// it can.
  ///
  /// This is not writing the set, and it is deliberately not asked to be the
  /// owner of one: a view says nothing about the set and changes nothing
  /// anybody else sees, so a player who cannot change a note of the running
  /// order can still say what key they read it in and which parts they want on
  /// screen.
  Future<ScoreSet> saveEntryView(
    String setId,
    String entryId, {
    int? transposition,
    List<String>? hiddenParts,
    double? zoom,
  }) =>
      _sync.saveEntryView(
        setId,
        entryId,
        transposition: transposition,
        hiddenParts: hiddenParts,
        zoom: zoom,
      );

  /// Marks the set as deleted here, and tells the server as soon as it can.
  ///
  /// It is kept rather than dropped, the same way the server keeps it: a sync
  /// only asks about what changed since the last one, so a set that was simply
  /// forgotten here would be fetched straight back in as something new.
  Future<void> deleteSet(String setId) => _sync.delete(setId);

  // -------------------------------------------------------------------------
  // SYNCING
  // -------------------------------------------------------------------------

  /// Squares what is here with what is on the server: what was written here
  /// goes out first, so that a set that has just been pushed is not read back
  /// as it was before the push, and what the server has changed since the last
  /// sync comes in after.
  Future<void> syncWithApi() => _sync.syncWithApi();

  /// Forgets every set on this device, what is owed about them included,
  /// for a device that is handed to somebody else.
  Future<void> forgetAll() => _sync.forgetAll();
}

/// An edit the server refused, which this app has taken back.
///
/// Giving up on an edit is the one thing the app does behind the player's back,
/// so it says so when it happens.
class SyncProblem {
  const SyncProblem({
    required this.setId,
    required this.title,
    required this.action,
    required this.error,
  });

  final String setId;
  final String title;
  final String action;
  final SetsApiException error;
}

typedef _Engine
    = SyncEngine<ScoreSet, SetEntry, SetsApiException, SyncProblem>;

/// What a set is to the [SyncEngine]: where it is stored, which endpoints it
/// is written to, and that its songs are sent in their running order.
class _Sets
    extends SyncAdapter<ScoreSet, SetEntry, SetsApiException, SyncProblem> {
  _Sets(this._store, this._api);

  final LocalStore _store;
  final SetsApi _api;

  @override
  String get noun => 'Set';

  @override
  Future<List<Map<String, Object?>>> readStored() => _store.readSets();

  @override
  Future<void> writeStored(List<Map<String, Object?>> records) =>
      _store.writeSets(records);

  @override
  Future<void> forgetStored() => _store.forgetSets();

  @override
  ScoreSet fromJson(Map<String, Object?> json) => ScoreSet.fromJson(json);

  @override
  ScoreSet fromApi(Map<String, dynamic> json, DateTime syncedAt) =>
      ScoreSet.fromApi(json, syncedAt);

  @override
  SetEntry entryFromApi(Map<String, dynamic> json) => SetEntry.fromApi(json);

  @override
  Future<bool> canBeReached() => _api.canBeReached();

  @override
  Future<List<Map<String, dynamic>>> list(
    DateTime? changesSince,
    DateTime changesUntil,
    String token,
  ) =>
      _api.listSets(changesSince, changesUntil, token);

  @override
  Future<Map<String, dynamic>?> fetch(String id, String token) =>
      _api.getSet(id, token);

  @override
  Future<Map<String, dynamic>> put(
    String id,
    String token,
    Map<String, Object?> write,
  ) =>
      _api.putSet(id, token, write);

  @override
  Future<void> remove(String id, String token) => _api.deleteSet(id, token);

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
  SyncProblem problem({
    required String id,
    required String title,
    required String action,
    required SetsApiException error,
  }) =>
      SyncProblem(setId: id, title: title, action: action, error: error);

  @override
  Future<EntryRun<ScoreSet, SetEntry, SetsApiException>?> startEntries(
    _Engine engine,
    ScoreSet set,
  ) async {
    final queued = _inTheOrderToSend(set);
    final known = await _orderOnTheServer(engine, set, queued);
    if (known == null) return null;
    return _RunningOrder(queued, known);
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
    _Engine engine,
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
      final token = await engine.token();
      if (token == null) return null;
      final json = await _api.getSet(set.id, token);
      if (json == null) {
        // Not there for this user any more: each write will say so.
        return here;
      }
      return [
        for (final entry in json['entries'] as List? ?? const [])
          '${(entry as Map)['id']}',
      ];
    } catch (error, stackTrace) {
      if (error is SetsApiException) await engine.forgetTokenIfRefused(error);
      _log.warning(
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
class _RunningOrder extends EntryRun<ScoreSet, SetEntry, SetsApiException> {
  _RunningOrder(this.queue, this._order);

  @override
  final List<PendingEntry> queue;

  /// The server's running order, as it is after what was sent so far.
  List<String> _order;

  /// Where the song that was written last was asked to go.
  int _position = 0;

  @override
  Map<String, Object?> writeOf(ScoreSet set, SetEntry entry) {
    _position = _placeAfter(_order, set.entries, entry);
    return {
      'score_id': entry.scoreId,
      'description': entry.description,
      'transposition': entry.transposition,
      'position': _position,
    };
  }

  @override
  void removed(String entryId) =>
      _order = [for (final id in _order) if (id != entryId) id];

  @override
  void written(String entryId, Map<String, dynamic> stored) {
    final placed = stored['position'];
    _order = _placedAt(
      _order,
      entryId,
      placed is num ? placed.round() : _position,
    );
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

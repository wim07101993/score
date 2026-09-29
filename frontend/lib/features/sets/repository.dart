import 'package:flutter/foundation.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/models.dart';
import 'package:uuid/uuid.dart';

/// The sets, as this device has them.
///
/// A set is written here first and sent afterwards. That is not a nicety: a set
/// is a playlist for a gig, and a gig is where there is no network, so a write
/// that could only be made online is a write that could not be made when it was
/// needed. Every edit is therefore stored locally, marked as owed to the
/// server, and pushed the first time the server can be reached — at the end of
/// the edit if that is right away, and at the next sync otherwise.
///
/// What that costs is that this device and the server can disagree, and the
/// rule for that is: what was written here wins until it has been pushed. A set
/// with an edit still owed is never overwritten by what a sync brings in,
/// because that edit is the newer of the two by definition — it was made after
/// the last time this device heard anything at all.
class SetsRepository extends ChangeNotifier {
  SetsRepository(
    this._store,
    this._api,
    this._oidc,
  );

  static const _uuid = Uuid();

  final LocalStore _store;
  final SetsApi _api;
  final OidcApi _oidc;

  /// Every set that is kept here, the deleted ones included.
  final Map<String, ScoreSet> _sets = {};

  final List<void Function(SyncProblem)> _problemListeners = [];

  /// The push that is out for each set, if there is one.
  final Map<String, Future<void>> _pushing = {};

  /// The sets there are, most recently changed first. The deleted ones are kept
  /// but are no longer sets anyone has.
  List<ScoreSet> get sets {
    final all = _sets.values.where((set) => set.deletedAt == null).toList();
    all.sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));
    return all;
  }

  ScoreSet? getSet(String setId) {
    final set = _sets[setId];
    return set == null || set.deletedAt != null ? null : set;
  }

  /// Whether anything here is still owed to the server.
  bool get hasPendingChanges => _sets.values.any((set) => set.owesAnything);

  Future<void> init() async {
    for (final record in await _store.readSets()) {
      final set = ScoreSet.fromJson(record);
      _sets[set.id] = set;
    }
    notifyListeners();
  }

  void addSyncProblemListener(void Function(SyncProblem) listener) =>
      _problemListeners.add(listener);

  void removeSyncProblemListener(void Function(SyncProblem) listener) =>
      _problemListeners.remove(listener);

  void _reportProblem(SyncProblem problem) {
    for (final listener in [..._problemListeners]) {
      listener(problem);
    }
  }

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
  }) async {
    final setId = id ?? _uuid.v4();
    final existing = _sets[setId];
    if (existing != null && !existing.isOwner) {
      throw StateError(
          "Set with id '$setId' belongs to someone else and cannot be changed.");
    }

    final set = ScoreSet(
      id: setId,
      title: title,
      description: description,
      entries: existing?.entries ?? const [],
      sharedWith: addressesOf(sharedWith),
      isOwner: existing?.isOwner ?? true,
      lastChangedAt: DateTime.now(),
      // Nothing is carried over from a deletion, so writing a set that had been
      // deleted brings it back: a client that still has it and edits it is
      // saying it should exist.
      lastSyncedAt: existing?.lastSyncedAt,
      pendingChange: PendingChange.write,
      pendingViews: existing?.pendingViews ?? const [],
      pendingEntries: existing?.pendingEntries ?? const [],
    );

    await _keep([set]);
    await _pushIfPossible(setId);
    return _sets[setId]!;
  }

  /// Puts one score into a set, or changes how it is played, and hands the set
  /// back as it now reads.
  ///
  /// The set is closed up around it: an entry written at a place the set
  /// already has an entry in puts that one and everything after it back by one,
  /// and an entry that is already in the set and is written at another place
  /// moves there. A place beyond the end of the set is the end of the set, and
  /// no place at all is the end of the set.
  Future<ScoreSet> saveEntry(
    String setId, {
    String? id,
    String? scoreId,
    String? description,
    int? transposition,
    int? position,
  }) async {
    final existing = _ownedSet(setId);

    final entryId = id ?? _uuid.v4();
    final known =
        existing.entries.where((entry) => entry.id == entryId).firstOrNull;

    final written = SetEntry(
      id: entryId,
      scoreId: scoreId ?? known?.scoreId,
      description: description ?? known?.description ?? '',
      transposition: transpositionOf(transposition ?? known?.transposition),
      // How this user reads it is theirs and is written on its own, so an entry
      // that is moved or renamed keeps it.
      view: known?.view ?? const EntryView(),
      synced: known?.synced ?? false,
    );

    final others =
        existing.entries.where((entry) => entry.id != entryId).toList();
    final at = (position ?? others.length).clamp(0, others.length);

    await _keep([
      _withEntries(
        existing,
        [...others.sublist(0, at), written, ...others.sublist(at)],
        _owing(existing.pendingEntries, entryId, PendingChange.write),
      )
    ]);
    await _pushIfPossible(setId);
    return _sets[setId]!;
  }

  /// Takes one score out of a set and closes the running order up around it.
  ///
  /// What every player said about how they look at it goes with it: it was
  /// about a song that is no longer played.
  Future<ScoreSet> deleteEntry(String setId, String entryId) async {
    final existing = _ownedSet(setId);
    final entry =
        existing.entries.where((candidate) => candidate.id == entryId).firstOrNull;
    if (entry == null) {
      return existing;
    }

    // An entry the server never heard of is nothing to tell it about: there is
    // no row there to remove, and whatever was queued about it is about a song
    // that was never played anywhere.
    final owing = entry.synced
        ? _owing(existing.pendingEntries, entryId, PendingChange.delete)
        : existing.pendingEntries.where((owed) => owed.id != entryId).toList();

    await _keep([
      _withEntries(
        existing,
        existing.entries.where((candidate) => candidate.id != entryId).toList(),
        owing,
      )
    ]);
    await _pushIfPossible(setId);
    return _sets[setId]!;
  }

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
    int transposition = 0,
    List<String> hiddenParts = const [],
  }) async {
    final existing = _sets[setId];
    if (existing == null || existing.deletedAt != null) {
      throw StateError("Set with id '$setId' is not on this device.");
    }
    if (!existing.entries.any((entry) => entry.id == entryId)) {
      throw StateError("Set '$setId' has no entry '$entryId'.");
    }

    await _keep([
      _withEntryView(
        existing,
        entryId,
        EntryView(
          transposition: transpositionOf(transposition),
          hiddenParts: [...hiddenParts],
        ),
        owed: true,
      )
    ]);
    await _pushIfPossible(setId);
    return _sets[setId]!;
  }

  /// Marks the set as deleted here, and tells the server as soon as it can.
  ///
  /// It is kept rather than dropped, the same way the server keeps it: a sync
  /// only asks about what changed since the last one, so a set that was simply
  /// forgotten here would be fetched straight back in as something new.
  Future<void> deleteSet(String setId) async {
    final existing = _sets[setId];
    if (existing == null || existing.deletedAt != null) {
      return;
    }
    if (!existing.isOwner) {
      throw StateError(
          "Set with id '$setId' belongs to someone else and cannot be deleted.");
    }

    final now = DateTime.now();
    await _keep([
      existing.copyWith(
        lastChangedAt: now,
        deletedAt: now,
        // A set the server never heard of is nothing to tell it about: there is
        // no row there to mark as gone, and the headstone here is enough.
        pendingChange: existing.lastSyncedAt == null ? null : PendingChange.delete,
        clearPendingChange: existing.lastSyncedAt == null,
        // How anybody read a set that is gone is not worth a request, and
        // neither is what was put into it or taken out of it.
        pendingViews: const [],
        pendingEntries: const [],
      )
    ]);
    await _pushIfPossible(setId);
  }

  /// The set with the given id, when it is this user's to arrange.
  ScoreSet _ownedSet(String setId) {
    final set = _sets[setId];
    if (set == null || set.deletedAt != null) {
      throw StateError("Set with id '$setId' is not on this device.");
    }
    if (!set.isOwner) {
      throw StateError(
          "Set with id '$setId' belongs to someone else and cannot be changed.");
    }
    return set;
  }

  // -------------------------------------------------------------------------
  // SYNCING
  // -------------------------------------------------------------------------

  /// Squares what is here with what is on the server: what was written here
  /// goes out first, so that a set that has just been pushed is not read back
  /// as it was before the push, and what the server has changed since the last
  /// sync comes in after.
  Future<void> syncWithApi() async {
    await _pushPending();
    await _pull();
  }

  /// Sends everything that is still owed to the server.
  ///
  /// One set failing does not stop the others: they are separate writes and
  /// there is no reason a set that can be stored should wait for one that
  /// cannot.
  Future<void> _pushPending() async {
    final owing = _sets.values.where((set) => set.owesAnything).toList();
    for (final set in owing) {
      await _push(set.id);
    }
  }

  Future<void> _pushIfPossible(String setId) async {
    final set = _sets[setId];
    if (set == null || !set.owesAnything) {
      return;
    }
    if (!await _api.canBeReached() || !await _oidc.canBeReached()) {
      debugPrint('the api cannot be reached; what was written stays queued');
      return;
    }
    await _push(setId);
  }

  /// Sends what is owed for one set and squares what is here with the answer.
  ///
  /// This never throws. A push that failed for a reason that may pass is left
  /// queued for the next sync; one the server will refuse just as firmly next
  /// time is given up on, the set is read back the way the server has it, and
  /// the problem is reported — an edit that is quietly dropped is worse than
  /// one that is dropped loudly.
  Future<void> _push(String setId) async {
    // One push at a time for a set. Two of them out at once would each square
    // what is here with an answer that knows nothing about the other, and
    // whichever came back last would put back what the first one had already
    // moved past. A push asked for while one is out goes after it, and reads
    // what is owed at that point.
    final previous = _pushing[setId] ?? Future<void>.value();
    final next =
        previous.catchError((Object _) {}).then((_) => _pushNow(setId));
    _pushing[setId] = next;
    try {
      await next;
    } finally {
      if (identical(_pushing[setId], next)) {
        _pushing.remove(setId);
      }
    }
  }

  Future<void> _pushNow(String setId) async {
    final set = _sets[setId];
    if (set == null) {
      return;
    }

    if (set.pendingChange != null) {
      await _pushSet(setId);
    }
    // In that order, because each of them is written against the one before it:
    // an entry is written against a set, and a view against an entry. A set the
    // server has not been told about is nothing to hang an entry off, and an
    // entry it has not been told about is nothing to hang a view off — so
    // whatever did not get through keeps what depends on it queued behind it.
    if (_sets[setId]?.pendingChange != null) {
      return;
    }
    await _pushEntries(setId);
    await _pushViews(setId);
  }

  Future<void> _pushSet(String setId) async {
    final set = _sets[setId];
    if (set == null) return;
    final action = set.pendingChange!;

    try {
      final token = await _oidc.getActiveAccessToken();
      if (token == null) return;

      if (action == PendingChange.delete) {
        await _api.deleteSet(set.id, token);
        // Written again while the delete was on its way, which brings it back:
        // that write is newer than the delete and is still owed.
        final current = _sets[setId]!;
        if (!_changedSince(set)) {
          await _keep([current.copyWith(clearPendingChange: true)]);
        }
        return;
      }

      final stored = await _api.putSet(set.id, token, {
        'title': set.title,
        'description': set.description,
        'shared_with': set.sharedWith,
      });
      final syncedAt = _syncedOutsideAPull(set);
      final current = _sets[setId]!;
      if (_changedSince(set)) {
        // It was written again, or deleted, while this was on its way. That is
        // newer than the answer and is still owed; all the answer says that is
        // still true is that the server now has the set.
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
      // What comes back is the set as the server has it, which is the truth
      // about what a set is — but not about what has been done to it here and
      // not sent yet, which is newer than anything the server can say. That is
      // read from the set as it is now rather than as it was sent: a song may
      // have been put in while the request was out.
      await _keep([
        _carryPending(ScoreSet.fromApi(stored, syncedAt), current),
      ]);
    } on SetsApiException catch (error) {
      if (error.isWorthRetrying) {
        debugPrint('failed to $action set ${set.id}; it stays queued: $error');
        return;
      }
      await _giveUpOn(set, action, error);
    }
  }

  /// Sends what has been done to the running order here, one song at a time and
  /// in the order it was done.
  Future<void> _pushEntries(String setId) async {
    for (final owed in [...?_sets[setId]?.pendingEntries]) {
      final set = _sets[setId];
      if (set == null) return;

      final entry =
          set.entries.where((candidate) => candidate.id == owed.id).firstOrNull;
      if (owed.action == PendingChange.write && entry == null) {
        // It was taken out again before this ever went; there is nothing left
        // to write.
        await _keep([_withoutPendingEntry(set, owed.id)]);
        continue;
      }

      try {
        final token = await _oidc.getActiveAccessToken();
        if (token == null) return;

        if (owed.action == PendingChange.delete) {
          await _api.deleteEntry(setId, owed.id, token);
          await _keep([_settled(_sets[setId]!, owed)]);
          continue;
        }

        final stored = await _api.putEntry(setId, owed.id, token, {
          'score_id': entry!.scoreId,
          'description': entry.description,
          'transposition': entry.transposition,
          'position': _placeOnTheServer(set, entry),
        });
        final current = _sets[setId]!;
        final settled = _isStillOwed(current, owed)
            ? _withStoredEntry(current, stored)
            : _writtenBehindAWrite(current, owed.id);
        await _keep([settled]);
      } on SetsApiException catch (error) {
        if (error.isWorthRetrying) {
          debugPrint('failed to ${owed.action} entry ${owed.id}; it stays'
              ' queued: $error');
          continue;
        }

        final current = _sets[setId];
        if (current != null) {
          await _keep([_settled(current, owed)]);
        }
        _reportProblem(SyncProblem(
          setId: setId,
          title: current?.title ?? '',
          action: 'entry ${owed.action}',
          error: error,
        ));
      }
    }
  }

  /// Sends how this user reads the entries they have said something about.
  Future<void> _pushViews(String setId) async {
    for (final entryId in [...?_sets[setId]?.pendingViews]) {
      final set = _sets[setId];
      final entry =
          set?.entries.where((candidate) => candidate.id == entryId).firstOrNull;
      if (set == null) return;
      if (entry == null) {
        // The entry is no longer in the set, so how it was read is not about
        // anything any more.
        await _keep([_withoutPendingView(set, entryId)]);
        continue;
      }

      // The entry itself is still owed, so the server has nothing to hang this
      // on yet. It waits for the song, the way the song waits for the set.
      if (set.pendingEntries.any((owed) => owed.id == entryId)) {
        continue;
      }

      try {
        final token = await _oidc.getActiveAccessToken();
        if (token == null) return;

        final stored = await _api.putEntryView(setId, entryId, token, {
          'transposition': entry.view.transposition,
          'hidden_parts': entry.view.hiddenParts,
        });
        final current = _sets[setId]!;
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
            EntryView.fromJson(stored),
            owed: false,
          )
        ]);
      } on SetsApiException catch (error) {
        if (error.isWorthRetrying) {
          debugPrint('failed to save the view of entry $entryId; it stays'
              ' queued: $error');
          continue;
        }

        final current = _sets[setId];
        if (current != null) {
          await _keep([_withoutPendingView(current, entryId)]);
        }
        _reportProblem(SyncProblem(
          setId: setId,
          title: current?.title ?? '',
          action: 'view',
          error: error,
        ));
      }
    }
  }

  /// Takes back an edit the server will not have, and reports it.
  ///
  /// The set is read back by its id rather than left to the next sync, which
  /// only asks about what changed since the last one and would not cover a set
  /// that was last changed before that. When that read fails too, what is here
  /// stays as it was: it is no longer owed to anybody, so it is stale rather
  /// than lost, and any later change to it brings it back in step.
  ///
  /// Only the set's own write is taken back. The songs put into it and the
  /// views of them are separate writes the server has not refused, so they stay
  /// owed — unless there is no set left to put them into. And a set that was
  /// written again while the refused write was out is left owing that newer
  /// write, which the server has not said anything about yet.
  Future<void> _giveUpOn(
      ScoreSet set, String action, SetsApiException error) async {
    Map<String, dynamic>? fromApi;
    try {
      final token = await _oidc.getActiveAccessToken();
      fromApi = token == null ? null : await _api.getSet(set.id, token);
    } catch (readError) {
      final current = _sets[set.id] ?? set;
      if (!_changedSince(set)) {
        await _keep([current.copyWith(clearPendingChange: true)]);
      }
      _reportProblem(SyncProblem(
          setId: set.id, title: set.title, action: action, error: error));
      return;
    }

    final current = _sets[set.id] ?? set;
    if (fromApi == null) {
      // There is no such set for this user: whatever was written here is a set
      // that does not exist, and a headstone is what that looks like. Nothing
      // that was to go into it can go anywhere.
      await _keep([
        current.copyWith(
          deletedAt: current.deletedAt ?? DateTime.now(),
          clearPendingChange: true,
          pendingViews: const [],
          pendingEntries: const [],
        )
      ]);
    } else if (!_changedSince(set)) {
      await _keep([
        _carryPending(
            ScoreSet.fromApi(fromApi, _syncedOutsideAPull(set)), current),
      ]);
    }

    _reportProblem(SyncProblem(
        setId: set.id, title: set.title, action: action, error: error));
  }

  /// Reads in everything that changed on the server since the last time it said
  /// anything, the sets that were deleted there included.
  Future<void> _pull() async {
    final token = await _oidc.getActiveAccessToken();
    if (token == null) return;

    // The end of the window is what is recorded as synced, and not the moment
    // the answer arrives: a set that changed while the request was on its way
    // is not in this answer, and has to be in the next one.
    final syncedAt = DateTime.now();
    final fromApi = await _api.listSets(
        _lastSyncedAt()?.subtract(pullOverlap), syncedAt, token);
    if (fromApi.isEmpty) {
      return;
    }

    final toStore = <ScoreSet>[];
    for (final json in fromApi) {
      final existing = _sets['${json['id']}'];
      // What has been written here and not sent yet was written after the last
      // thing the server told us, so it is the newer of the two and is kept on
      // top of the answer; the rest of what the server says is taken as it
      // stands. That goes for the songs in a set whose own write is still owed
      // too: skipping the answer whole would move the window past what other
      // devices put into it, and it would never be asked for again.
      final carried = _carryPending(ScoreSet.fromApi(json, syncedAt), existing);
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

  /// The last moment the server said anything about a set, which is where the
  /// next change window starts.
  DateTime? _lastSyncedAt() {
    DateTime? latest;
    for (final set in _sets.values) {
      final synced = set.lastSyncedAt;
      if (synced != null && (latest == null || synced.isAfter(latest))) {
        latest = synced;
      }
    }
    return latest;
  }

  /// What a set that was read by itself, rather than listed in a pull, records
  /// as synced.
  ///
  /// It must not move the watermark: another set may have changed since the
  /// last pull, and a later moment here would make the next pull skip it. But
  /// it cannot stay empty either, because an empty one means the server has
  /// never heard of the set, and a set like that is deleted without asking.
  DateTime _syncedOutsideAPull(ScoreSet set) =>
      set.lastSyncedAt ?? _lastSyncedAt() ?? DateTime.utc(1970);

  /// Whether the set itself was written or deleted here since [sent] was read,
  /// which a push has to know once its answer is in: the request was out for a
  /// while, and the player did not stop in the meantime.
  bool _changedSince(ScoreSet sent) =>
      _sets[sent.id]?.lastChangedAt != sent.lastChangedAt;

  Future<void> _keep(List<ScoreSet> sets) async {
    if (sets.isEmpty) {
      return;
    }
    for (final set in sets) {
      _sets[set.id] = set;
    }
    await _store.writeSets([for (final set in sets) set.toJson()]);
    notifyListeners();
  }
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

// ---------------------------------------------------------------------------
// PUTTING A SET BACK TOGETHER
// ---------------------------------------------------------------------------

/// The set the server just described, with what this device has written and not
/// sent put back on top of it.
///
/// Anything still owed was written after the last thing the server said about
/// it, so it is the newer of the two. That is the running order as a whole
/// while a song is waiting to be sent — the answer cannot know about the song,
/// and half a running order is not one — and the view of any entry that is
/// waiting.
ScoreSet _carryPending(ScoreSet incoming, ScoreSet? existing) {
  if (existing == null) {
    return incoming;
  }

  final owedEntries = existing.pendingEntries;
  final entries =
      _mergedEntries(incoming.entries, existing.entries, owedEntries);
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

/// The running order the server has, with the songs that are owed to it as this
/// device has them.
///
/// Only those are taken from here. The rest is the server's, and that includes
/// whatever another device put in or took out: keeping this device's order
/// whole while one song is owed would lose that for good, since the next sync
/// only asks about what changed after this one. A song that is owed goes back
/// in at the place it has here, which is where it is sent to as well.
List<SetEntry> _mergedEntries(
  List<SetEntry> incoming,
  List<SetEntry> existing,
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

/// Where an entry goes in the running order the server has.
///
/// That is its place here counting only the songs the server has heard of: a
/// song that is still waiting to be sent is not in the server's order, so
/// counting it would put this one that much further down. The songs are sent
/// in the order they were put in, so by the time a song goes, the ones that
/// were put in ahead of it and have gone are counted.
int _placeOnTheServer(ScoreSet set, SetEntry entry) => set.entries
    .takeWhile((candidate) => candidate.id != entry.id)
    .where((candidate) => candidate.synced)
    .length;

/// The same set with a different running order, and a different idea of what is
/// owed about it.
ScoreSet _withEntries(
        ScoreSet set, List<SetEntry> entries, List<PendingEntry> pendingEntries) =>
    set.copyWith(
      entries: entries,
      pendingViews: _keptOf(set.pendingViews, entries),
      pendingEntries: pendingEntries,
    );

/// The same set with one entry as the server now has it, and nothing left owed
/// about that entry.
///
/// The place it came back in is where it goes: the server closes the set up
/// around an entry, so writing one can move the others. That place is in the
/// server's order, which does not have the songs still waiting to be sent, so
/// it is counted in the songs here that the server has too; and an entry that
/// is already at that place here stays where it is among the ones that are
/// still waiting.
ScoreSet _withStoredEntry(ScoreSet set, Map<String, dynamic> json) {
  var stored = SetEntry.fromApi(json);
  final others = set.entries.where((entry) => entry.id != stored.id).toList();
  final position = json['position'] is num
      ? (json['position'] as num).round()
      : null;

  // Its own view is the one this device has: the answer carries the view the
  // server knew about, which is older than one that is still waiting to be
  // sent.
  final here = set.entries.where((entry) => entry.id == stored.id).firstOrNull;
  if (here != null && set.pendingViews.contains(stored.id)) {
    stored = stored.copyWith(view: here.view);
  }

  final at = here != null &&
          (position == null || _placeOnTheServer(set, here) == position)
      ? set.entries.indexOf(here)
      : _placeHere(others, position);

  return _withEntries(
    set,
    [...others.sublist(0, at), stored, ...others.sublist(at)],
    _withoutOwed(set.pendingEntries, stored.id),
  );
}

/// Where the given place in the server's order is in [entries]: just before the
/// song the server has at that place, or the end when there is none.
int _placeHere(List<SetEntry> entries, int? position) {
  if (position == null) {
    return entries.length;
  }
  var seen = 0;
  for (final (index, entry) in entries.indexed) {
    if (!entry.synced) continue;
    if (seen == position) return index;
    seen++;
  }
  return entries.length;
}

ScoreSet _withoutPendingEntry(ScoreSet set, String entryId) =>
    _withEntries(set, set.entries, _withoutOwed(set.pendingEntries, entryId));

/// Whether [owed] is still what is owed about its entry, rather than something
/// said about the entry since. Every edit queues a new one, so a write that was
/// out while the entry was edited again is not the one still in the queue.
bool _isStillOwed(ScoreSet set, PendingEntry owed) =>
    set.pendingEntries.any((candidate) => identical(candidate, owed));

/// The same set with [owed] no longer owed, and anything said about the entry
/// since it went out still owed.
ScoreSet _settled(ScoreSet set, PendingEntry owed) => _withEntries(
      set,
      set.entries,
      set.pendingEntries
          .where((candidate) => !identical(candidate, owed))
          .toList(),
    );

/// The same set once the server has taken an entry that was changed again here
/// while it was on its way.
///
/// What is here is newer and stays owed; the answer only says that the server
/// has the entry now. So an entry that was taken out in the meantime, which
/// was dropped as one the server had never heard of, has to be taken out there
/// too.
ScoreSet _writtenBehindAWrite(ScoreSet set, String entryId) {
  final here = set.entries.where((entry) => entry.id == entryId).firstOrNull;
  if (here != null) {
    return set.copyWith(entries: [
      for (final entry in set.entries)
        if (entry.id == entryId) entry.copyWith(synced: true) else entry,
    ]);
  }
  if (set.pendingEntries.any((owed) => owed.id == entryId)) {
    return set;
  }
  return set.copyWith(
    pendingEntries: _owing(set.pendingEntries, entryId, PendingChange.delete),
  );
}

/// What is owed about the entries of a set, with one entry now owing this.
///
/// An entry is owed once however often it is written: what goes out is the
/// entry as it now reads, not every edit that was made to it. The last thing
/// said about it is what is said, so a write that follows a delete replaces it.
List<PendingEntry> _owing(
        List<PendingEntry> owed, String entryId, String action) =>
    [..._withoutOwed(owed, entryId), PendingEntry(entryId, action)];

List<PendingEntry> _withoutOwed(List<PendingEntry> owed, String entryId) =>
    owed.where((entry) => entry.id != entryId).toList();

/// The same set with one entry looked at differently, and that entry marked as
/// owed to the server or no longer owed.
ScoreSet _withEntryView(ScoreSet set, String entryId, EntryView view,
    {required bool owed}) {
  final pending = set.pendingViews.where((id) => id != entryId).toList();
  if (owed) {
    pending.add(entryId);
  }

  return set.copyWith(
    entries: [
      for (final entry in set.entries)
        if (entry.id != entryId) entry else entry.copyWith(view: view),
    ],
    pendingViews: pending,
  );
}

ScoreSet _withoutPendingView(ScoreSet set, String entryId) => set.copyWith(
      pendingViews: set.pendingViews.where((id) => id != entryId).toList(),
    );

/// The entry ids of [owed] that the given entries still have. A view of an
/// entry that is no longer in the set is about a song that is no longer played.
List<String> _keptOf(List<String> owed, List<SetEntry> entries) {
  if (owed.isEmpty) {
    return const [];
  }
  return owed.where((id) => entries.any((entry) => entry.id == id)).toList();
}

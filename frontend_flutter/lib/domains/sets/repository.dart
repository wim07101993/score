import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/local_store.dart';
import '../auth/oidc_api.dart';
import 'api.dart';
import 'models.dart';

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
  SetsRepository(this._store, this._api, this._oidc);

  final LocalStore _store;
  final SetsApi _api;
  final OidcApi _oidc;

  static const _uuid = Uuid();

  /// Every set that is kept here, the deleted ones included.
  final Map<String, ScoreSet> _sets = {};

  final List<void Function(SyncProblem)> _problemListeners = [];

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
      // Writing a set that had been deleted brings it back: a client that still
      // has it and edits it is saying it should exist.
      deletedAt: null,
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
      scoreId: scoreId ?? known?.scoreId ?? '',
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
        // How anybody read a set that is gone is not worth a request.
        pendingViews: const [],
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
        await _keep([set.copyWith(clearPendingChange: true)]);
        return;
      }

      final stored = await _api.putSet(set.id, token, {
        'title': set.title,
        'description': set.description,
        'shared_with': set.sharedWith,
      });
      // What comes back is the set as the server has it, which is the truth
      // about what a set is — but not about what has been done to it here and
      // not sent yet, which is newer than anything the server can say.
      await _keep([
        _carryPending(ScoreSet.fromApi(stored, DateTime.now()), set),
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
    for (final owed in [...(_sets[setId]?.pendingEntries ?? const [])]) {
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
          await _keep([_withoutPendingEntry(_sets[setId]!, owed.id)]);
          continue;
        }

        final stored = await _api.putEntry(setId, owed.id, token, {
          'score_id': entry!.scoreId,
          'description': entry.description,
          'transposition': entry.transposition,
          'position': set.entries.indexOf(entry),
        });
        await _keep([_withStoredEntry(_sets[setId]!, stored)]);
      } on SetsApiException catch (error) {
        if (error.isWorthRetrying) {
          debugPrint('failed to ${owed.action} entry ${owed.id}; it stays'
              ' queued: $error');
          continue;
        }

        final current = _sets[setId];
        if (current != null) {
          await _keep([_withoutPendingEntry(current, owed.id)]);
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
    for (final entryId in [...(_sets[setId]?.pendingViews ?? const [])]) {
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
        await _keep([
          _withEntryView(
            _sets[setId]!,
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
  Future<void> _giveUpOn(
      ScoreSet set, String action, SetsApiException error) async {
    Map<String, dynamic>? fromApi;
    try {
      final token = await _oidc.getActiveAccessToken();
      fromApi = token == null ? null : await _api.getSet(set.id, token);
    } catch (readError) {
      await _keep([set.copyWith(clearPendingChange: true)]);
      _reportProblem(SyncProblem(
          setId: set.id, title: set.title, action: action, error: error));
      return;
    }

    if (fromApi == null) {
      // There is no such set for this user: whatever was written here is a set
      // that does not exist, and a headstone is what that looks like.
      await _keep([
        set.copyWith(
          deletedAt: set.deletedAt ?? DateTime.now(),
          clearPendingChange: true,
        )
      ]);
    } else {
      await _keep([ScoreSet.fromApi(fromApi, DateTime.now())]);
    }

    _reportProblem(SyncProblem(
        setId: set.id, title: set.title, action: action, error: error));
  }

  /// Reads in everything that changed on the server since the last time it said
  /// anything, the sets that were deleted there included.
  Future<void> _pull() async {
    final token = await _oidc.getActiveAccessToken();
    if (token == null) return;

    final fromApi = await _api.listSets(_lastSyncedAt(), DateTime.now(), token);
    if (fromApi.isEmpty) {
      return;
    }

    final syncedAt = DateTime.now();
    final toStore = <ScoreSet>[];
    for (final json in fromApi) {
      final existing = _sets['${json['id']}'];
      // A set that still owes the server a write was written here after the
      // last thing the server told us, so it is the newer of the two and the
      // answer is out of date the moment it arrives.
      if (existing?.pendingChange != null) {
        continue;
      }
      // What has been written here and not sent yet is newer than the answer
      // for the same reason, and is kept on top of it; the rest of what the
      // server says is taken as it stands.
      toStore.add(_carryPending(ScoreSet.fromApi(json, syncedAt), existing));
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
  final entries = owedEntries.isNotEmpty ? existing.entries : incoming.entries;
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
/// around an entry, so writing one can move the others.
ScoreSet _withStoredEntry(ScoreSet set, Map<String, dynamic> json) {
  var stored = SetEntry.fromApi(json);
  final others = set.entries.where((entry) => entry.id != stored.id).toList();
  final position = (json['position'] is num
          ? (json['position'] as num).round()
          : others.length)
      .clamp(0, others.length);

  // Its own view is the one this device has: the answer carries the view the
  // server knew about, which is older than one that is still waiting to be
  // sent.
  final here = set.entries.where((entry) => entry.id == stored.id).firstOrNull;
  if (here != null && set.pendingViews.contains(stored.id)) {
    stored = stored.copyWith(view: here.view);
  }

  return _withEntries(
    set,
    [...others.sublist(0, position), stored, ...others.sublist(position)],
    _withoutOwed(set.pendingEntries, stored.id),
  );
}

ScoreSet _withoutPendingEntry(ScoreSet set, String entryId) =>
    _withEntries(set, set.entries, _withoutOwed(set.pendingEntries, entryId));

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

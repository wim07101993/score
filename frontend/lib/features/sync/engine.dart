/// Keeping sets and collections on this device, and in step with the server.
///
/// A set and a collection are written here first and sent afterwards. That is
/// not a nicety: a set is a playlist for a gig and a collection is the book a
/// player adds a piece to where the book is, and both of those are where there
/// is no network — so a write that could only be made online is a write that
/// could not be made when it was needed. Every edit is therefore stored
/// locally, marked as owed to the server, and pushed the first time the server
/// can be reached — at the end of the edit if that is right away, and at the
/// next sync otherwise.
///
/// What that costs is that this device and the server can disagree, and the
/// rule for that is: what was written here wins until it has been pushed. A
/// set or a collection with an edit still owed is never overwritten by what a
/// sync brings in, because that edit is the newer of the two by definition —
/// it was made after the last time this device heard anything at all.
///
/// All of that is the same for the two of them, and is said once, here, in
/// [SyncEngine]. What is their own — the running order of a set, and a
/// collection holding a piece once — is said by each through its
/// [SyncAdapter], and in the [EntryRun] it sends its entries with.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:score/api.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sets/models.dart';

/// What a set or a collection is to the engine that keeps it: how it is
/// stored, how it is read, which endpoints it is written to, and what is its
/// own about sending its entries.
abstract class SyncAdapter<R extends SyncedRecord<R, E>,
    E extends SyncedEntry<E>, X extends ApiException, P> {
  /// What one of them is called when an error names it: `Set`, `Collection`.
  String get noun;

  Future<List<Map<String, Object?>>> readStored();
  Future<void> writeStored(List<Map<String, Object?>> records);
  Future<void> forgetStored();

  R fromJson(Map<String, Object?> json);
  R fromApi(Map<String, dynamic> json, DateTime syncedAt);
  E entryFromApi(Map<String, dynamic> json);

  Future<bool> canBeReached();
  Future<List<Map<String, dynamic>>> list(
    DateTime? changesSince,
    DateTime changesUntil,
    String token,
  );
  Future<Map<String, dynamic>?> fetch(String id, String token);
  Future<Map<String, dynamic>> put(
    String id,
    String token,
    Map<String, Object?> write,
  );
  Future<void> remove(String id, String token);
  Future<Map<String, dynamic>> putEntry(
    String id,
    String entryId,
    String token,
    Map<String, Object?> write,
  );
  Future<void> removeEntry(String id, String entryId, String token);
  Future<Map<String, dynamic>> putEntryView(
    String id,
    String entryId,
    String token,
    Map<String, Object?> write,
  );

  /// The problem a listener is told about when an edit was given up on.
  P problem({
    required String id,
    required String title,
    required String action,
    required X error,
  });

  /// How what is owed about the entries of [record] is sent this time, or
  /// null when it cannot be yet and stays queued for the next sync.
  Future<EntryRun<R, E, X>?> startEntries(
    SyncEngine<R, E, X, P> engine,
    R record,
  );
}

/// One go at sending what is owed about the entries of one set or collection.
///
/// Everything it is not asked here is the same for both: what is still owed
/// once an answer is in, what is given up on, and what waits for the next
/// sync.
abstract class EntryRun<R, E, X extends ApiException> {
  /// What is owed, in the order it is sent in.
  List<PendingEntry> get queue;

  /// What is written to the server for [entry], which is in [record].
  Map<String, Object?> writeOf(R record, E entry);

  /// The server has taken [entryId] out.
  void removed(String entryId) {}

  /// The server has taken the write of [entryId], and answered with [stored].
  void written(String entryId, Map<String, dynamic> stored) {}

  /// Whether [error] is a refusal that is dealt with here, by [take], rather
  /// than retried or reported the way every other refusal is.
  bool takes(X error) => false;

  Future<void> take(PendingEntry owed, X error) async {}

  /// What is left to do once the queue has been gone through, or null when
  /// there is nothing.
  Future<void>? finish() => null;
}

/// The sets or the collections, as this device has them: see the library
/// documentation above for what that means and why.
class SyncEngine<R extends SyncedRecord<R, E>, E extends SyncedEntry<E>,
    X extends ApiException, P> {
  SyncEngine(
    this._adapter,
    this._oidc,
    this._changed,
  );

  final SyncAdapter<R, E, X, P> _adapter;
  final OidcApi _oidc;

  /// What is called when what is held here changed, for whoever is listening
  /// to the repository this engine keeps.
  final VoidCallback _changed;

  /// What one of them is called in the middle of a message.
  String get _kind => _adapter.noun.toLowerCase();

  /// Every one that is kept here, the deleted ones included.
  final Map<String, R> _records = {};

  final List<void Function(P)> _problemListeners = [];

  /// The push that is out for each one, if there is one.
  final Map<String, Future<void>> _pushing = {};

  /// How many writes the server has taken for each one since the app started,
  /// so that a pull can tell whether one landed while its own answer was being
  /// made — see [_pull].
  final Map<String, int> _taken = {};

  void _tookAWrite(String id) => _taken[id] = (_taken[id] ?? 0) + 1;

  /// Takes in what other tabs of the app stored since this one read the store.
  ///
  /// On the web every tab is a program of its own over the one store. The store
  /// hears what the other tabs write, but what is held here is what was read
  /// when this tab started — and pushing that, or writing an edit on top of it,
  /// would put back what another tab has since changed or sent. Everything this
  /// tab changes is stored before anything else is done with it, so what the
  /// store holds is never older than what is here.
  ///
  Future<void> takeInWhatOthersStored() async {
    final keptBefore = {..._kept};
    final stored = await _adapter.readStored();
    var changed = false;

    // One that is here and no longer in the store was forgotten by another tab
    // — the device was handed to somebody else (see [forgetAll]) — since every
    // one this tab keeps is stored before anything is done with it.
    final storedIds = {for (final record in stored) '${record['id']}'};
    for (final id in [..._records.keys]) {
      if (storedIds.contains(id) ||
          _kept[id] != keptBefore[id] ||
          (_writing[id] ?? 0) > 0) {
        continue;
      }
      _records.remove(id);
      _seen.remove(id);
      changed = true;
    }

    for (final record in stored) {
      final id = '${record['id']}';
      // What this tab changed since the read began, or is still writing, is
      // newer than what was read: an edit made a moment ago must not be put
      // back to what the store held before it.
      if (_kept[id] != keptBefore[id] || (_writing[id] ?? 0) > 0) {
        continue;
      }
      final taken = _adapter.fromJson(record);
      // A push that is out squares what it sent with what is here by which
      // object it is, so what this tab stored itself is left as it is: taken
      // in again, the push would find nothing it sent and send it once more.
      // What another tab stored is taken in all the same. An edit made here
      // while the push is out is put together from what is held here, and
      // written whole over the store — so one built on this tab's own copy
      // would drop what the other tab stored and has not sent. The push only
      // sends again what it can no longer find.
      if (_pushing.containsKey(id) && _asStored(taken) == _seen[id]) {
        continue;
      }
      _seen[id] = _asStored(taken);
      final held = _records[id];
      if (held != null && jsonEncode(held.toJson()) == jsonEncode(record)) {
        continue;
      }
      _records[taken.id] = taken;
      changed = true;
    }
    if (changed) _changed();
  }

  /// How often this tab has changed each record, and how many of those
  /// changes are still being written to the store: see
  /// [takeInWhatOthersStored].
  final Map<String, int> _kept = {};
  final Map<String, int> _writing = {};

  /// Each one as this tab last read it from the store or wrote it there, so
  /// that a write by another tab can be told apart from one of this tab's own:
  /// see [keepAnswer].
  final Map<String, String> _seen = {};

  String _asStored(R record) => jsonEncode(record.toJson());

  /// A token the API refused is spent, however long this device thinks it has
  /// left, and is forgotten so that the next request asks for a fresh one
  /// rather than sending it again — see [OidcApi.forgetAccessToken].
  Future<void> forgetTokenIfRefused(X error) async {
    if (error.status == 401) {
      await _oidc.forgetAccessToken();
    }
  }

  /// The token to send, without asking anybody to sign in for it: a push or a
  /// pull happens behind the player's back.
  ///
  /// None while what is here belongs to somebody other than the user signed
  /// in (see [OidcApi.dataOwner]): pushed with their token, it would become
  /// theirs.
  Future<String?> token() async {
    if (!await _oidc.holdsTheDataOfTheSignedInUser()) {
      return null;
    }
    return _oidc.getActiveAccessToken(signIn: false);
  }

  /// Forgets every one that is kept here, owed or not, for a device that is
  /// handed to somebody else.
  ///
  /// A push that is out is waited for first: whatever it keeps of its answer
  /// would otherwise be written back after the store was emptied.
  Future<void> forgetAll() async {
    await Future.wait([
      for (final pushing in _pushing.values) pushing.catchError((Object _) {}),
    ]);
    for (final id in _records.keys) {
      // So that an answer still being read for one of them is not kept.
      _kept[id] = (_kept[id] ?? 0) + 1;
    }
    _records.clear();
    _seen.clear();
    await _adapter.forgetStored();
    _changed();
  }

  /// The ones there are, most recently changed first. The deleted ones are kept
  /// but are no longer anything anyone has.
  List<R> get all {
    final all =
        _records.values.where((record) => record.deletedAt == null).toList();
    all.sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));
    return all;
  }

  /// The one with the given id, unless it is not here or has been deleted.
  R? get(String id) {
    final record = _records[id];
    return record == null || record.deletedAt != null ? null : record;
  }

  /// The one with the given id as it is held here, deleted or not.
  R? held(String id) => _records[id];

  /// Whether anything here is still owed to the server.
  bool get hasPendingChanges =>
      _records.values.any((record) => record.owesAnything);

  Future<void> init() async {
    for (final json in await _adapter.readStored()) {
      final record = _adapter.fromJson(json);
      _records[record.id] = record;
      _seen[record.id] = _asStored(record);
    }
    _changed();
  }

  void addSyncProblemListener(void Function(P) listener) =>
      _problemListeners.add(listener);

  void removeSyncProblemListener(void Function(P) listener) =>
      _problemListeners.remove(listener);

  void reportProblem(P problem) {
    for (final listener in [..._problemListeners]) {
      listener(problem);
    }
  }

  void _report(String id, String title, String action, X error) =>
      reportProblem(
        _adapter.problem(id: id, title: title, action: action, error: error),
      );

  // -------------------------------------------------------------------------
  // WRITING
  // -------------------------------------------------------------------------

  /// Stores what [write] makes of the one with the given id — what it is, and
  /// who may read it — and hands it back.
  ///
  /// One that is only shared with this user is not this user's to change, and
  /// writing one is refused rather than queued: there is no moment later at
  /// which the server would take it.
  Future<R> save(String id, R Function(R? existing) write) async {
    await takeInWhatOthersStored();
    final existing = _records[id];
    if (existing != null && !existing.isOwner) {
      throw StateError("${_adapter.noun} with id '$id' belongs to someone"
          ' else and cannot be changed.');
    }

    await keep([write(existing)]);
    await pushIfPossible(id);
    return _records[id]!;
  }

  /// Takes one entry out and closes what is left up around it.
  ///
  /// What every player said about how they look at it goes with it: it was
  /// about an entry that is no longer there.
  Future<R> deleteEntry(String id, String entryId) async {
    await takeInWhatOthersStored();
    final existing = owned(id);
    final entry = existing.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    if (entry == null) {
      return existing;
    }

    // An entry of one the server has never had is nothing to tell it about:
    // the entries wait for what they are in (see _pushNow), so none of them
    // can have reached it. Any other entry is told about, whether or not an
    // answer ever said the server has it: a write the server took may have
    // had its answer lost on the way back, and the entry would come back with
    // the next pull. Removing one it never had is answered as done.
    final stillOwed = entry.synced || existing.lastSyncedAt != null
        ? owing(existing.pendingEntries, entryId, PendingChange.delete)
        : withoutOwed(existing.pendingEntries, entryId);

    await keep([
      withEntries(
        existing,
        existing.entries.where((candidate) => candidate.id != entryId).toList(),
        stillOwed,
      )
    ]);
    await pushIfPossible(id);
    return _records[id]!;
  }

  /// Stores how this user looks at one entry, and tells the server as soon as
  /// it can.
  ///
  /// This is not writing the set or the collection, and it is deliberately not
  /// asked to be the owner of one: a view says nothing about it and changes
  /// nothing anybody else sees, so a player who cannot change a note of the
  /// running order, or add a piece to the book, can still say what key they
  /// read it in, which parts they want on screen, and how big they draw it.
  Future<R> saveEntryView(
    String id,
    String entryId, {
    int? transposition,
    List<String>? hiddenParts,
    double? zoom,
  }) async {
    await takeInWhatOthersStored();
    final existing = _records[id];
    if (existing == null || existing.deletedAt != null) {
      throw StateError(
          "${_adapter.noun} with id '$id' is not on this device.");
    }
    final entry = existing.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    if (entry == null) {
      throw StateError("${_adapter.noun} '$id' has no entry '$entryId'.");
    }

    await keep([
      _withEntryView(
        existing,
        entryId,
        // A view is written whole, so what is not said here is what the entry
        // is read as now: saying only that the key changed is not saying to
        // put the parts that are off screen back on, or to draw it at the size
        // it is written at.
        EntryView(
          transposition:
              transpositionOf(transposition ?? entry.view.transposition),
          hiddenParts: [...(hiddenParts ?? entry.view.hiddenParts)],
          zoom: zoomOf(zoom ?? entry.view.zoom),
        ),
        owed: true,
      )
    ]);
    await pushIfPossible(id);
    return _records[id]!;
  }

  /// Marks the one with the given id as deleted here, and tells the server as
  /// soon as it can.
  ///
  /// It is kept rather than dropped, the same way the server keeps it: a sync
  /// only asks about what changed since the last one, so one that was simply
  /// forgotten here would be fetched straight back in as something new.
  Future<void> delete(String id) async {
    await takeInWhatOthersStored();
    final existing = _records[id];
    if (existing == null || existing.deletedAt != null) {
      return;
    }
    if (!existing.isOwner) {
      throw StateError("${_adapter.noun} with id '$id' belongs to someone"
          ' else and cannot be deleted.');
    }

    final now = DateTime.now();
    await keep([
      existing.copyWith(
        lastChangedAt: now,
        deletedAt: now,
        // Told to the server even when no answer ever said it has it: a first
        // write it took may have had its answer lost on the way back, and the
        // next pull would bring it back. Deleting one it never had is answered
        // as done, so what that costs is one request.
        pendingChange: PendingChange.delete,
        // How anybody read one that is gone is not worth a request, and
        // neither is what was put into it or taken out of it.
        pendingViews: const [],
        pendingEntries: const [],
      )
    ]);
    await pushIfPossible(id);
  }

  /// The one with the given id, when it is this user's to arrange or fill.
  R owned(String id) {
    final record = _records[id];
    if (record == null || record.deletedAt != null) {
      throw StateError(
          "${_adapter.noun} with id '$id' is not on this device.");
    }
    if (!record.isOwner) {
      throw StateError("${_adapter.noun} with id '$id' belongs to someone"
          ' else and cannot be changed.');
    }
    return record;
  }

  // -------------------------------------------------------------------------
  // SYNCING
  // -------------------------------------------------------------------------

  /// Squares what is here with what is on the server: what was written here
  /// goes out first, so that one that has just been pushed is not read back
  /// as it was before the push, and what the server has changed since the
  /// last sync comes in after.
  Future<void> syncWithApi() async {
    await takeInWhatOthersStored();
    await _pushPending();
    await _pull();
  }

  /// Sends everything that is still owed to the server.
  ///
  /// One failing does not stop the others: they are separate writes and there
  /// is no reason one that can be stored should wait for one that cannot.
  Future<void> _pushPending() async {
    final owed =
        _records.values.where((record) => record.owesAnything).toList();
    for (final record in owed) {
      await _push(record.id);
    }
  }

  /// Pushes what is owed for the one with the given id, when the server and
  /// the provider that hands out its tokens are both there to be asked.
  ///
  /// Every edit waits for this, so the two are asked at the same time rather
  /// than one after the other: each of them may take seconds to say it is not
  /// there, and a player who is offline would wait for both of those in turn
  /// on every note they changed.
  Future<void> pushIfPossible(String id) async {
    final record = _records[id];
    if (record == null || !record.owesAnything) {
      return;
    }
    final reachable = await Future.wait([
      _adapter.canBeReached(),
      _oidc.canBeReached(),
    ]);
    if (reachable.contains(false)) {
      debugPrint('the api cannot be reached; what was written stays queued');
      return;
    }
    await _push(id);
  }

  /// Sends what is owed for one and squares what is here with the answer.
  ///
  /// This never throws. A push that failed for a reason that may pass is left
  /// queued for the next sync; one the server will refuse just as firmly next
  /// time is given up on, what was written is read back the way the server has
  /// it, and the problem is reported — an edit that is quietly dropped is
  /// worse than one that is dropped loudly.
  Future<void> _push(String id) async {
    // One push at a time for each. Two of them out at once would each square
    // what is here with an answer that knows nothing about the other, and
    // whichever came back last would put back what the first one had already
    // moved past. A push asked for while one is out goes after it, and reads
    // what is owed at that point.
    final previous = _pushing[id] ?? Future<void>.value();
    final next = previous.catchError((Object _) {}).then((_) => _pushNow(id));
    _pushing[id] = next;
    try {
      await next;
    } finally {
      if (identical(_pushing[id], next)) {
        _pushing.remove(id);
      }
    }
  }

  Future<void> _pushNow(String id) async {
    final record = _records[id];
    if (record == null) {
      return;
    }

    if (record.pendingChange != null) {
      await _pushRecord(id);
    }
    // In that order, because each of them is written against the one before it:
    // an entry is written against a set or a collection, and a view against an
    // entry. One the server has not been told about is nothing to hang an entry
    // off, and an entry it has not been told about is nothing to hang a view
    // off — so whatever did not get through keeps what depends on it queued
    // behind it. That goes for one the server has never had at all, too: one
    // whose first write it refused keeps its entries queued until a write it
    // takes.
    final now = _records[id];
    if (now == null || now.pendingChange != null || now.lastSyncedAt == null) {
      return;
    }
    await _pushEntries(id);
    await _pushViews(id);
  }

  Future<void> _pushRecord(String id) async {
    final record = _records[id];
    if (record == null) return;
    final action = record.pendingChange!;

    try {
      final token = await this.token();
      if (token == null) return;

      if (action == PendingChange.delete) {
        await _adapter.remove(record.id, token);
        _tookAWrite(id);
        // Written again while the delete was on its way, which brings it back:
        // that write is newer than the delete and is still owed.
        final current = _records[id]!;
        if (!changedSince(record)) {
          await keepAnswer(current.copyWith(clearPendingChange: true));
        }
        return;
      }

      final stored = await _adapter.put(record.id, token, {
        'title': record.title,
        'description': record.description,
        'shared_with': record.sharedWith,
      });
      _tookAWrite(id);
      final syncedAt = syncedOutsideAPull(record);
      final current = _records[id]!;
      if (changedSince(record)) {
        // It was written again, or deleted, while this was on its way. That is
        // newer than the answer and is still owed; all the answer says that is
        // still true is that the server now has it.
        await keepAnswer(
          current.copyWith(
            lastSyncedAt: syncedAt,
            pendingChange: current.deletedAt == null
                ? PendingChange.write
                : PendingChange.delete,
          ),
        );
        return;
      }
      // What comes back is what the server has, which is the truth about what
      // a set or a collection is — but not about what has been done to it here
      // and not sent yet, which is newer than anything the server can say.
      // That is read from what is here now rather than from what was sent: an
      // entry may have been put in while the request was out.
      await keepAnswer(
        carryPending(_adapter.fromApi(stored, syncedAt), current),
      );
    } on X catch (error) {
      await forgetTokenIfRefused(error);
      if (error.isWorthRetrying) {
        debugPrint('failed to $action $_kind ${record.id}; it stays queued:'
            ' $error');
        return;
      }
      await _giveUpOn(record, action, error);
    } catch (error) {
      // Anything that is not the API answering — a token that could not be
      // refreshed over a network that went away, an answer that is not the
      // API's — says nothing about what was written. It stays queued, the way
      // it does when the network is down, rather than failing an edit that is
      // stored.
      debugPrint('failed to $action $_kind ${record.id}; it stays queued:'
          ' $error');
    }
  }

  /// Sends what has been done to the entries here, one entry at a time and in
  /// the order the [EntryRun] the adapter starts says.
  ///
  /// One entry failing for a reason that may pass stops neither the others nor
  /// the views: they are separate writes about separate entries.
  Future<void> _pushEntries(String id) async {
    final record = _records[id];
    if (record == null || record.pendingEntries.isEmpty) return;
    final run = await _adapter.startEntries(this, record);
    if (run == null) return;
    await _sendEntries(id, run);
    final finishing = run.finish();
    if (finishing != null) await finishing;
  }

  Future<void> _sendEntries(String id, EntryRun<R, E, X> run) async {
    for (final owed in run.queue) {
      final record = _records[id];
      if (record == null) return;

      final entry = record.entries
          .where((candidate) => candidate.id == owed.id)
          .firstOrNull;
      if (owed.action == PendingChange.write && entry == null) {
        // It was taken out again before this ever went; there is nothing left
        // to write. Only this write is settled: taking it out may have queued a
        // delete of its own, which still has to go.
        if (!await keepAnswer(_settled(record, owed))) return;
        continue;
      }

      try {
        final token = await this.token();
        if (token == null) return;

        if (owed.action == PendingChange.delete) {
          await _adapter.removeEntry(id, owed.id, token);
          _tookAWrite(id);
          run.removed(owed.id);
          if (!await keepAnswer(_settled(_records[id]!, owed))) return;
          continue;
        }

        final stored = await _adapter.putEntry(
          id,
          owed.id,
          token,
          run.writeOf(record, entry!),
        );
        _tookAWrite(id);
        run.written(owed.id, stored);
        final current = _records[id]!;
        final settled = isStillOwed(current, owed)
            ? _withStoredEntry(current, stored)
            : _writtenBehindAWrite(current, owed.id);
        if (!await keepAnswer(settled)) return;
      } on X catch (error) {
        await forgetTokenIfRefused(error);
        if (run.takes(error)) {
          await run.take(owed, error);
          continue;
        }
        if (error.isWorthRetrying) {
          debugPrint('failed to ${owed.action} entry ${owed.id}; it stays'
              ' queued: $error');
          continue;
        }

        // Kept as an answer, like any other: the refusal was a round trip,
        // and another tab may have stored something about this one since.
        final current = _records[id];
        if (current != null) {
          await keepAnswer(_settled(current, owed));
        }
        _report(id, current?.title ?? '', 'entry ${owed.action}', error);
      } catch (error) {
        // Not the API answering (see _pushRecord): this and whatever comes
        // after it stay queued for the next sync.
        debugPrint('failed to ${owed.action} entry ${owed.id}; it stays'
            ' queued: $error');
        return;
      }
    }
  }

  /// Sends how this user reads the entries they have said something about.
  ///
  /// Each entry is its own write, and one that fails stops neither the others
  /// nor what it is in: they are separate things said about separate entries.
  Future<void> _pushViews(String id) async {
    for (final entryId in [...?_records[id]?.pendingViews]) {
      final record = _records[id];
      if (record == null) return;
      final entry = record.entries
          .where((candidate) => candidate.id == entryId)
          .firstOrNull;
      if (entry == null) {
        // The entry is no longer there, so how it was read is not about
        // anything any more.
        if (!await keepAnswer(_withoutPendingView(record, entryId))) return;
        continue;
      }

      // The entry itself is still owed, so the server has nothing to hang this
      // on yet. It waits for the entry, the way the entry waits for what it is
      // in.
      if (record.pendingEntries.any((owed) => owed.id == entryId)) {
        continue;
      }

      try {
        final token = await this.token();
        if (token == null) return;

        // Whole, the size included: a view is replaced by what is written, and
        // one written without a size is read by the server as the size the
        // score is written at.
        final stored = await _adapter.putEntryView(id, entryId, token, {
          'transposition': entry.view.transposition,
          'hidden_parts': entry.view.hiddenParts,
          'zoom': entry.view.zoom,
        });
        _tookAWrite(id);
        final current = _records[id]!;
        final now = current.entries
            .where((candidate) => candidate.id == entryId)
            .firstOrNull;
        if (now == null || !identical(now.view, entry.view)) {
          // It was looked at differently again while this was on its way, and
          // that is what goes next.
          continue;
        }
        final kept = await keepAnswer(
          _withEntryView(
            current,
            entryId,
            EntryView.fromJson(stored),
            owed: false,
          ),
        );
        if (!kept) return;
      } on X catch (error) {
        await forgetTokenIfRefused(error);
        if (error.isWorthRetrying) {
          debugPrint('failed to save the view of entry $entryId; it stays'
              ' queued: $error');
          continue;
        }

        final current = _records[id];
        if (current != null) {
          await keepAnswer(_withoutPendingView(current, entryId));
        }
        _report(id, current?.title ?? '', 'view', error);
      } catch (error) {
        // Not the API answering (see _pushRecord): it stays queued.
        debugPrint('failed to save the view of entry $entryId; it stays'
            ' queued: $error');
        return;
      }
    }
  }

  /// Takes back an edit the server will not have, and reports it.
  ///
  /// What was written is read back by its id rather than left to the next
  /// sync, which only asks about what changed since the last one and would not
  /// cover one that was last changed before that. When that read fails too,
  /// what is here stays as it was: it is no longer owed to anybody, so it is
  /// stale rather than lost, and any later change to it brings it back in step.
  ///
  /// Only its own write is taken back. The entries put into it and the views
  /// of them are separate writes the server has not refused, so they stay owed
  /// — unless there is nothing left to put them into. And one that was written
  /// again while the refused write was out is left owing that newer write,
  /// which the server has not said anything about yet.
  Future<void> _giveUpOn(R record, String action, X error) async {
    Map<String, dynamic>? fromApi;
    try {
      // No token is not the server saying there is no such thing: it is not
      // having asked, and is handled as a read that failed.
      final token = await this.token();
      if (token == null) {
        throw StateError('there is no token to read the $_kind back with');
      }
      fromApi = await _adapter.fetch(record.id, token);
    } catch (readError) {
      final current = _records[record.id] ?? record;
      if (!changedSince(record)) {
        await keepAnswer(current.copyWith(clearPendingChange: true));
      }
      _report(record.id, record.title, action, error);
      return;
    }

    final current = _records[record.id] ?? record;
    if (fromApi == null && current.lastSyncedAt == null) {
      // The server never had it and has just refused to — a mistyped address
      // in one made offline, say. There is nothing there to take it back to, so
      // what the player made here is kept, with the entries put into it, and
      // those wait (see _pushNow) for a write of it the server will take.
      if (!changedSince(record)) {
        await keepAnswer(current.copyWith(clearPendingChange: true));
      }
    } else if (fromApi == null) {
      // There is no such thing for this user: whatever was written here is one
      // that does not exist, and a headstone is what that looks like. Nothing
      // that was to go into it can go anywhere.
      await keepAnswer(
        current.copyWith(
          deletedAt: current.deletedAt ?? DateTime.now(),
          clearPendingChange: true,
          pendingViews: const [],
          pendingEntries: const [],
        ),
      );
    } else if (!changedSince(record)) {
      await keepAnswer(
        carryPending(
          _adapter.fromApi(fromApi, syncedOutsideAPull(record)),
          current,
        ),
      );
    }

    _report(record.id, record.title, action, error);
  }

  /// Reads in everything that changed on the server since the last time it said
  /// anything, what was deleted there included.
  Future<void> _pull() async {
    final token = await this.token();
    if (token == null) return;

    // The end of the window is what is recorded as synced, and not the moment
    // the answer arrives: one that changed while the request was on its way is
    // not in this answer, and has to be in the next one.
    final takenBefore = {..._taken};
    final asked = DateTime.now();
    final fromApi = await _adapter.list(
        _lastSyncedAt()?.subtract(pullOverlap), asked, token);
    if (fromApi.isEmpty) {
      return;
    }
    final syncedAt = watermarkOf(fromApi, asked);

    // A push that is out for one in the answer lands first, so that what it
    // stores and what this stores are not written over each other.
    await Future.wait([
      for (final json in fromApi)
        if (_pushing['${json['id']}'] case final pushing?)
          pushing.catchError((Object _) {}),
    ]);
    // And what other tabs stored while the answer was on its way: it is put
    // together from what is held here, and written whole over what the store
    // has, so an entry another tab put in and has not sent would be dropped.
    await takeInWhatOthersStored();

    final toStore = <R>[];
    for (final json in fromApi) {
      // The server took a write for this one while the answer was being made,
      // and may have made the answer before it: what is here came back from
      // that write, and is at least as new. Taking the answer would put back a
      // title just changed, or drop an entry just put in. The write moved it
      // into the next window, which reads it again.
      if (_taken['${json['id']}'] != takenBefore['${json['id']}']) {
        continue;
      }
      final existing = _records['${json['id']}'];
      // What has been written here and not sent yet was written after the last
      // thing the server told us, so it is the newer of the two and is kept on
      // top of the answer; the rest of what the server says is taken as it
      // stands. That goes for the entries of one whose own write is still owed
      // too: skipping the answer whole would move the window past what other
      // devices put into it, and it would never be asked for again.
      final carried = carryPending(_adapter.fromApi(json, syncedAt), existing);
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

    await keep(toStore);
  }

  /// The last moment the server said anything about any of them, which is
  /// where the next change window starts.
  DateTime? _lastSyncedAt() {
    DateTime? latest;
    for (final record in _records.values) {
      final synced = record.lastSyncedAt;
      if (synced != null && (latest == null || synced.isAfter(latest))) {
        latest = synced;
      }
    }
    return latest;
  }

  /// What one that was read by itself, rather than listed in a pull, records
  /// as synced.
  ///
  /// It must not move the watermark: another may have changed since the last
  /// pull, and a later moment here would make the next pull skip it. But it
  /// cannot stay empty either, because an empty one means the server has never
  /// heard of it, and one like that is deleted without asking.
  DateTime syncedOutsideAPull(R record) =>
      record.lastSyncedAt ?? _lastSyncedAt() ?? DateTime.utc(1970);

  /// Whether it was itself written or deleted here since [sent] was read, which
  /// a push has to know once its answer is in: the request was out for a
  /// while, and the player did not stop in the meantime.
  bool changedSince(R sent) =>
      _records[sent.id]?.lastChangedAt != sent.lastChangedAt;

  Future<void> keep(List<R> records) async {
    if (records.isEmpty) {
      return;
    }
    for (final record in records) {
      _records[record.id] = record;
      _seen[record.id] = _asStored(record);
      _kept[record.id] = (_kept[record.id] ?? 0) + 1;
      _writing[record.id] = (_writing[record.id] ?? 0) + 1;
    }
    try {
      await _adapter
          .writeStored([for (final record in records) record.toJson()]);
    } finally {
      for (final record in records) {
        _writing[record.id] = _writing[record.id]! - 1;
      }
    }
    _changed();
  }

  /// Keeps what a push made of the server's answer, unless it was changed
  /// while the answer was on its way by something that answer knows nothing
  /// about. Answers whether it was kept.
  ///
  /// [record] was put together from what this tab held, and another tab of the
  /// web app may have stored an edit of its own since — an entry put in, say,
  /// that is owed and not sent. Written over, that edit would be gone for good.
  /// So when the store no longer holds what this tab last saw there, what it
  /// holds is taken in instead and the answer is dropped. Nothing is lost by
  /// that: what was sent is still owed in what the store holds, since every
  /// edit is stored before it is sent, and sending it again writes the same
  /// thing. The same goes for this tab changing it while the store was being
  /// read, which makes [record] out of date.
  Future<bool> keepAnswer(R record) async {
    final keptBefore = _kept[record.id];
    // A write of this tab's own that is still on its way may not be in what
    // the read finds, and what is found then is not another tab's.
    final writingBefore = _writing[record.id] ?? 0;
    final json = (await _adapter.readStored())
        .where((json) => '${json['id']}' == record.id)
        .firstOrNull;
    if (_kept[record.id] != keptBefore) {
      return false;
    }
    if (json != null &&
        writingBefore == 0 &&
        (_writing[record.id] ?? 0) == 0) {
      final stored = _adapter.fromJson(json);
      if (_asStored(stored) != _seen[record.id]) {
        _records[record.id] = stored;
        _seen[record.id] = _asStored(stored);
        _changed();
        return false;
      }
    }
    await keep([record]);
    return true;
  }

  // -------------------------------------------------------------------------
  // PUTTING ONE BACK TOGETHER
  // -------------------------------------------------------------------------

  /// What the server just described, with what this device has written and not
  /// sent put back on top of it.
  ///
  /// Anything still owed was written after the last thing the server said about
  /// it, so it is the newer of the two. That is the entries as a whole while
  /// one of them is waiting to be sent — the answer cannot know about it, and
  /// half a running order is not one — and the view of any entry that is
  /// waiting.
  R carryPending(R incoming, R? existing) {
    if (existing == null) {
      return incoming;
    }

    final owedEntries = existing.pendingEntries;
    final entries = mergedEntries(
      incoming.entries,
      existing.entries,
      owedEntries,
      (entry) => entry.id,
    );
    final owedViews =
        keptOf(existing.pendingViews, entries.map((entry) => entry.id));

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

  /// The same one holding different entries, and with a different idea of
  /// what is owed about them.
  R withEntries(R record, List<E> entries, List<PendingEntry> pendingEntries) =>
      record.copyWith(
        entries: entries,
        pendingViews:
            keptOf(record.pendingViews, entries.map((entry) => entry.id)),
        pendingEntries: pendingEntries,
      );

  /// The same one with one entry as the server now has it, and nothing left
  /// owed about that entry.
  ///
  /// It stays where it is here, and one the server has that is not here yet
  /// goes on the end. A collection has no order, so there is nothing for the
  /// server to have moved. A song in a set was placed on the server behind the
  /// song it comes after here (see the running order in the sets repository),
  /// so the two orders agree about it; the place the server answers with is
  /// in an order that may still hold songs whose removal is owed, and moving
  /// it by that would move it away from where the player put it. Where the
  /// server's order differs about the other songs — another device moved them
  /// — the pull that follows the push brings it in.
  R _withStoredEntry(R record, Map<String, dynamic> json) {
    var stored = _adapter.entryFromApi(json);

    // Its own view is the one this device has: the answer carries the view the
    // server knew about, which is older than one that is still waiting to be
    // sent.
    final here =
        record.entries.where((entry) => entry.id == stored.id).firstOrNull;
    if (here != null && record.pendingViews.contains(stored.id)) {
      stored = stored.copyWith(view: here.view);
    }

    return withEntries(
      record,
      [
        for (final entry in record.entries)
          if (entry.id == stored.id) stored else entry,
        if (here == null) stored,
      ],
      withoutOwed(record.pendingEntries, stored.id),
    );
  }

  /// Whether [owed] is still what is owed about its entry, rather than
  /// something said about the entry since. Every edit queues a new one, so a
  /// write that was out while the entry was edited again is not the one still
  /// in the queue.
  bool isStillOwed(R record, PendingEntry owed) =>
      record.pendingEntries.any((candidate) => identical(candidate, owed));

  /// The same one with [owed] no longer owed, and anything said about the
  /// entry since it went out still owed.
  R _settled(R record, PendingEntry owed) => withEntries(
        record,
        record.entries,
        record.pendingEntries
            .where((candidate) => !identical(candidate, owed))
            .toList(),
      );

  /// The same one once the server has taken an entry that was changed again
  /// here while it was on its way.
  ///
  /// What is here is newer and stays owed; the answer only says that the
  /// server has the entry now. So an entry that was taken out in the meantime,
  /// which was dropped as one the server had never heard of, has to be taken
  /// out there too.
  R _writtenBehindAWrite(R record, String entryId) {
    final here =
        record.entries.where((entry) => entry.id == entryId).firstOrNull;
    if (here != null) {
      return record.copyWith(entries: [
        for (final entry in record.entries)
          if (entry.id == entryId) entry.copyWith(synced: true) else entry,
      ]);
    }
    if (record.pendingEntries.any((owed) => owed.id == entryId)) {
      return record;
    }
    return record.copyWith(
      pendingEntries:
          owing(record.pendingEntries, entryId, PendingChange.delete),
    );
  }

  /// The same one with one entry looked at differently, and that entry marked
  /// as owed to the server or no longer owed.
  R _withEntryView(
    R record,
    String entryId,
    EntryView view, {
    required bool owed,
  }) {
    final pending = record.pendingViews.where((id) => id != entryId).toList();
    if (owed) {
      pending.add(entryId);
    }

    return record.copyWith(
      entries: [
        for (final entry in record.entries)
          if (entry.id != entryId) entry else entry.copyWith(view: view),
      ],
      pendingViews: pending,
    );
  }

  R _withoutPendingView(R record, String entryId) => record.copyWith(
        pendingViews:
            record.pendingViews.where((id) => id != entryId).toList(),
      );
}

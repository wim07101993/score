import {EntryView, PendingChange, ScoreSet, SetDatabase, SetEntry} from "./database.js";
import {
  SetsApi,
  SetsApiError,
  WriteEntryViewDto,
  WriteSetDto,
  WriteSetEntryDto,
} from "./api.js";
import {OidcApi} from "../auth/oidc-api.js";
import {MAX_TRANSPOSITION, MIN_TRANSPOSITION} from "../scores/score-view.js";

/**
 * The sets, as this device has them.
 *
 * A set is written here first and sent afterwards. That is not a nicety: a set
 * is a playlist for a gig, and a gig is where there is no network, so a write
 * that could only be made online is a write that could not be made when it was
 * needed. Every edit is therefore stored locally, marked as owed to the server,
 * and pushed the first time the server can be reached — at the end of the edit
 * if that is right away, and at the next sync otherwise.
 *
 * What that costs is that this device and the server can disagree, and the rule
 * for that is: what was written here wins until it has been pushed. A set with
 * an edit still owed is never overwritten by what a sync brings in, because
 * that edit is the newer of the two by definition — it was made after the last
 * time this device heard anything at all.
 *
 * @typedef {function()} SetsChangedCallback
 * @typedef {{setId: string, title: string, action: string, error: SetsApiError}} SyncProblem
 * @typedef {function(SyncProblem)} SyncProblemCallback
 */
export class SetsRepository {
  /**
   * @param database {SetDatabase}
   * @param api {SetsApi}
   * @param oidc {OidcApi}
   */
  constructor(database, api, oidc) {
    this._database = database;
    this._api = api;
    this._oidc = oidc;
  }

  /**
   * Every set that is kept here, the deleted ones included.
   *
   * @type {Map<string, ScoreSet>}
   * @private
   */
  _sets = new Map();

  /**
   * @type {SetsChangedCallback[]}
   * @private
   */
  _setsChangesListeners = [];

  /**
   * @type {SyncProblemCallback[]}
   * @private
   */
  _syncProblemListeners = [];

  /**
   * The sets there are, most recently changed first. The deleted ones are kept
   * but are no longer sets anyone has.
   *
   * @return {ScoreSet[]}
   */
  get sets() {
    return Array.from(this._sets.values())
      .filter((set) => set.deleted_at == null)
      .sort((a, b) => (b.last_changed_at?.getTime() ?? 0) - (a.last_changed_at?.getTime() ?? 0));
  }

  /**
   * @param setId {string}
   * @return {ScoreSet|null}
   */
  getSet(setId) {
    const set = this._sets.get(setId);
    if (set == null || set.deleted_at != null) {
      return null;
    }
    return set;
  }

  /** @return {boolean} whether anything here is still owed to the server */
  get hasPendingChanges() {
    return Array.from(this._sets.values()).some((set) =>
      set.pending_change != null
      || set.pending_entries?.length > 0
      || set.pending_views?.length > 0);
  }

  async init() {
    const sets = await this._database.fetchSets();
    for (const set of sets) {
      this._sets.set(set.id, set);
    }
  }

  // --------------------------------------------------------------------------
  // WRITING
  // --------------------------------------------------------------------------

  /**
   * Stores what a set is — the gig, and who may read it — and hands it back.
   *
   * What is played in it is not touched: an entry is written on its own, so
   * correcting a title is correcting a title. A set that is created here is
   * created empty and filled afterwards, the same way it is on the server.
   *
   * The set is stored here whether or not the server can be reached; when it
   * can, it is pushed before this returns. When it cannot, what comes back is
   * what was written, marked as still owed.
   *
   * A set that is only shared with this user is not this user's to change, and
   * writing one is refused rather than queued: there is no moment later at
   * which the server would take it.
   *
   * @param draft {{id?: string, title: string, description?: string,
   *   shared_with?: string[]}}
   * @return {Promise<ScoreSet>}
   */
  async saveSet(draft) {
    const id = draft.id ?? crypto.randomUUID();
    const existing = this._sets.get(id);
    if (existing != null && existing.is_owner === false) {
      throw new Error(`Set with id '${id}' belongs to someone else and cannot be changed.`);
    }

    const set = new ScoreSet(
      id,
      draft.title ?? '',
      draft.description ?? '',
      existing?.entries ?? [],
      _addressesOf(draft.shared_with ?? []),
      existing?.is_owner ?? true,
      new Date(),
      // Writing a set that had been deleted brings it back: a client that still
      // has it and edits it is saying it should exist.
      null,
      existing?.last_synced_at ?? null,
      PendingChange.Write,
      existing?.pending_views ?? [],
      existing?.pending_entries ?? []);

    await this._store([set]);
    await this._pushIfPossible(id);
    return this._sets.get(id);
  }

  /**
   * Puts one score into a set, or changes how it is played, and hands the set
   * back as it now reads.
   *
   * The set is closed up around it: an entry written at a place the set already
   * has an entry in puts that one and everything after it back by one, and an
   * entry that is already in the set and is written at another place moves
   * there. A place beyond the end of the set is the end of the set, and no
   * place at all is the end of the set.
   *
   * Only the owner of a set arranges it. How anybody reads it is
   * {@link saveEntryView}, which everyone the set is shared with does for
   * themselves.
   *
   * @param setId {string}
   * @param entry {{id?: string, score_id: string, description?: string,
   *   transposition?: number, position?: number}}
   * @return {Promise<ScoreSet>}
   */
  async saveEntry(setId, entry) {
    const existing = this._ownedSet(setId);

    const entryId = entry.id ?? crypto.randomUUID();
    const known = existing.entries.find((candidate) => candidate.id === entryId);
    const written = new SetEntry(
      entryId,
      entry.score_id ?? known?.score_id,
      entry.description ?? known?.description ?? '',
      _transpositionOf(entry.transposition ?? known?.transposition),
      // How this user reads it is theirs and is written on its own, so an entry
      // that is moved or renamed keeps it.
      known?.view ?? new EntryView(),
      known?.synced ?? false);

    const others = existing.entries.filter((candidate) => candidate.id !== entryId);
    const position = Math.min(Math.max(entry.position ?? others.length, 0), others.length);

    await this._store([_withEntries(
      existing,
      [...others.slice(0, position), written, ...others.slice(position)],
      _owing(existing.pending_entries, entryId, PendingChange.Write))]);
    await this._pushIfPossible(setId);
    return this._sets.get(setId);
  }

  /**
   * Takes one score out of a set and closes the running order up around it.
   *
   * What every player said about how they look at it goes with it: it was about
   * a song that is no longer played.
   *
   * @param setId {string}
   * @param entryId {string}
   * @return {Promise<ScoreSet>}
   */
  async deleteEntry(setId, entryId) {
    const existing = this._ownedSet(setId);
    const entry = existing.entries.find((candidate) => candidate.id === entryId);
    if (entry == null) {
      return existing;
    }

    // An entry the server never heard of is nothing to tell it about: there is
    // no row there to remove, and whatever was queued about it is about a song
    // that was never played anywhere.
    const owing = entry.synced
      ? _owing(existing.pending_entries, entryId, PendingChange.Delete)
      : existing.pending_entries.filter((owed) => owed.id !== entryId);

    await this._store([_withEntries(
      existing,
      existing.entries.filter((candidate) => candidate.id !== entryId),
      owing)]);
    await this._pushIfPossible(setId);
    return this._sets.get(setId);
  }

  /**
   * The set with the given id, when it is this user's to arrange.
   *
   * @param setId {string}
   * @return {ScoreSet}
   * @private
   */
  _ownedSet(setId) {
    const set = this._sets.get(setId);
    if (set == null || set.deleted_at != null) {
      throw new Error(`Set with id '${setId}' is not on this device.`);
    }
    if (set.is_owner === false) {
      throw new Error(`Set with id '${setId}' belongs to someone else and cannot be changed.`);
    }
    return set;
  }

  /**
   * Stores how this user looks at one entry, and tells the server as soon as it
   * can.
   *
   * This is not writing the set, and it is deliberately not asked to be the
   * owner of one: a view says nothing about the set and changes nothing anybody
   * else sees, so a player who cannot change a note of the running order can
   * still say what key they read it in and which parts they want on screen.
   *
   * @param setId {string}
   * @param entryId {string}
   * @param view {{transposition?: number, hidden_parts?: string[]}}
   * @return {Promise<ScoreSet>}
   */
  async saveEntryView(setId, entryId, view) {
    const existing = this._sets.get(setId);
    if (existing == null || existing.deleted_at != null) {
      throw new Error(`Set with id '${setId}' is not on this device.`);
    }
    if (!existing.entries.some((entry) => entry.id === entryId)) {
      throw new Error(`Set '${setId}' has no entry '${entryId}'.`);
    }

    await this._store([_withEntryView(existing, entryId, _viewOf(view), true)]);
    await this._pushIfPossible(setId);
    return this._sets.get(setId);
  }

  /**
   * Marks the set as deleted here, and tells the server as soon as it can.
   *
   * It is kept rather than dropped, the same way the server keeps it: a sync
   * only asks about what changed since the last one, so a set that was simply
   * forgotten here would be fetched straight back in as something new.
   *
   * @param setId {string}
   * @return {Promise<void>}
   */
  async deleteSet(setId) {
    const existing = this._sets.get(setId);
    if (existing == null || existing.deleted_at != null) {
      return;
    }
    if (existing.is_owner === false) {
      throw new Error(`Set with id '${setId}' belongs to someone else and cannot be deleted.`);
    }

    const now = new Date();
    const deleted = new ScoreSet(
      existing.id,
      existing.title,
      existing.description,
      existing.entries,
      existing.shared_with,
      existing.is_owner,
      now,
      now,
      existing.last_synced_at,
      // A set the server never heard of is nothing to tell it about: there is
      // no row there to mark as gone, and the headstone here is enough.
      existing.last_synced_at == null ? PendingChange.None : PendingChange.Delete,
      // How anybody read a set that is gone is not worth a request.
      []);

    await this._store([deleted]);
    await this._pushIfPossible(setId);
  }

  // --------------------------------------------------------------------------
  // SYNCING
  // --------------------------------------------------------------------------

  /**
   * Squares what is here with what is on the server: what was written here goes
   * out first, so that a set that has just been pushed is not read back as it
   * was before the push, and what the server has changed since the last sync
   * comes in after.
   *
   * @return {Promise<void>}
   */
  async syncWithApi() {
    console.log('syncing api sets with local sets');
    await this._pushPending();
    await this._pull();
  }

  /**
   * Sends everything that is still owed to the server.
   *
   * One set failing does not stop the others: they are separate writes and
   * there is no reason a set that can be stored should wait for one that
   * cannot.
   *
   * @return {Promise<void>}
   * @private
   */
  async _pushPending() {
    const owing = Array.from(this._sets.values()).filter((set) =>
      set.pending_change != null
      || set.pending_entries.length > 0
      || set.pending_views.length > 0);
    for (const set of owing) {
      await this._push(set.id);
    }
  }

  /**
   * Pushes one set if there is anything to push and anything to push it to.
   *
   * @param setId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushIfPossible(setId) {
    const set = this._sets.get(setId);
    if (set == null
      || (set.pending_change == null
        && set.pending_entries.length === 0
        && set.pending_views.length === 0)) {
      return;
    }
    if (!await this._api.canBeReached() || !await this._oidc.canBeReached()) {
      console.log('the api cannot be reached; what was written stays queued');
      return;
    }
    await this._push(setId);
  }

  /**
   * Sends what is owed for one set and squares what is here with the answer.
   *
   * This never throws. A push that failed for a reason that may pass is left
   * queued for the next sync; one the server will refuse just as firmly next
   * time is given up on, the set is read back the way the server has it, and
   * the problem is reported — an edit that is quietly dropped is worse than one
   * that is dropped loudly.
   *
   * @param setId {string}
   * @return {Promise<void>}
   * @private
   */
  async _push(setId) {
    const set = this._sets.get(setId);
    if (set == null) {
      return;
    }

    if (set.pending_change != null) {
      await this._pushSet(setId);
    }
    // In that order, because each of them is written against the one before it:
    // an entry is written against a set, and a view against an entry. A set the
    // server has not been told about is nothing to hang an entry off, and an
    // entry it has not been told about is nothing to hang a view off — so
    // whatever did not get through keeps what depends on it queued behind it.
    if (this._sets.get(setId)?.pending_change != null) {
      return;
    }
    await this._pushEntries(setId);
    await this._pushViews(setId);
  }

  /**
   * Sends what has been done to the running order here, one song at a time and
   * in the order it was done.
   *
   * One entry failing stops neither the others nor the views: they are separate
   * writes about separate songs.
   *
   * @param setId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushEntries(setId) {
    const owed = this._sets.get(setId)?.pending_entries ?? [];
    for (const {id: entryId, action} of [...owed]) {
      const set = this._sets.get(setId);
      if (set == null) {
        return;
      }

      const entry = set.entries.find((candidate) => candidate.id === entryId);
      if (action === PendingChange.Write && entry == null) {
        // It was taken out again before this ever went; there is nothing left
        // to write.
        await this._store([_withoutPendingEntry(set, entryId)]);
        continue;
      }

      try {
        const accessToken = await this._oidc.getActiveAccessToken();
        if (accessToken == null) {
          return;
        }

        if (action === PendingChange.Delete) {
          await this._api.deleteEntry(setId, entryId, accessToken);
          await this._store([_withoutPendingEntry(this._sets.get(setId), entryId)]);
          continue;
        }

        const position = set.entries.indexOf(entry);
        const stored = await this._api.putEntry(setId, entryId, accessToken,
          new WriteSetEntryDto(entry.score_id, entry.description, entry.transposition, position));
        await this._store([_withStoredEntry(this._sets.get(setId), stored)]);
      } catch (error) {
        if (!(error instanceof SetsApiError) || error.isWorthRetrying) {
          console.error(`failed to ${action} entry ${entryId}; it stays queued`, error);
          continue;
        }

        console.error(`the server refused to ${action} entry ${entryId}; giving up on it`, error);
        const current = this._sets.get(setId);
        await this._store([_withoutPendingEntry(current, entryId)]);
        this._reportSyncProblem({
          setId: setId,
          title: current?.title ?? '',
          action: `entry ${action}`,
          error: error,
        });
      }
    }
  }

  /**
   * @param setId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushSet(setId) {
    const set = this._sets.get(setId);
    const action = set.pending_change;
    try {
      const accessToken = await this._oidc.getActiveAccessToken();
      if (accessToken == null) {
        return;
      }

      if (action === PendingChange.Delete) {
        await this._api.deleteSet(set.id, accessToken);
        await this._store([_synced(set, new Date())]);
        return;
      }

      const stored = await this._api.putSet(set.id, accessToken, _writeSetOf(set));
      // What comes back is the set as the server has it, which is the truth
      // about what a set is — but not about what has been done to it here and
      // not sent yet, which is newer than anything the server can say.
      await this._store([_carryPending(_setFromApi(stored, new Date()), set)]);
    } catch (error) {
      if (!(error instanceof SetsApiError) || error.isWorthRetrying) {
        console.error(`failed to ${action} set ${set.id}; it stays queued`, error);
        return;
      }

      console.error(`the server refused to ${action} set ${set.id}; giving up on it`, error);
      await this._giveUpOn(set, action, error);
    }
  }

  /**
   * Sends how this user reads the entries they have said something about.
   *
   * Each entry is its own write, and one that fails stops neither the others
   * nor the set it is in: they are separate things said about separate songs.
   *
   * @param setId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushViews(setId) {
    const owed = this._sets.get(setId)?.pending_views ?? [];
    for (const entryId of [...owed]) {
      const set = this._sets.get(setId);
      const entry = set?.entries.find((candidate) => candidate.id === entryId);
      if (set == null || entry == null) {
        // The entry is no longer in the set, so how it was read is not about
        // anything any more.
        if (set != null) {
          await this._store([_withoutPendingView(set, entryId)]);
        }
        continue;
      }

      // The entry itself is still owed, so the server has nothing to hang this
      // on yet. It waits for the song, the way the song waits for the set.
      if (set.pending_entries.some((owed) => owed.id === entryId)) {
        continue;
      }

      try {
        const accessToken = await this._oidc.getActiveAccessToken();
        if (accessToken == null) {
          return;
        }

        const stored = await this._api.putEntryView(setId, entryId, accessToken,
          new WriteEntryViewDto(entry.view.transposition, [...entry.view.hidden_parts]));
        await this._store([_withEntryView(this._sets.get(setId), entryId, _viewOf(stored), false)]);
      } catch (error) {
        if (!(error instanceof SetsApiError) || error.isWorthRetrying) {
          console.error(`failed to save the view of entry ${entryId}; it stays queued`, error);
          continue;
        }

        console.error(`the server refused the view of entry ${entryId}; giving up on it`, error);
        const set = this._sets.get(setId);
        await this._store([_withoutPendingView(set, entryId)]);
        this._reportSyncProblem({
          setId: setId,
          title: set?.title ?? '',
          action: 'view',
          error: error,
        });
      }
    }
  }

  /**
   * Takes back an edit the server will not have, and reports it.
   *
   * The set is read back by its id rather than left to the next sync, which
   * only asks about what changed since the last one and would not cover a set
   * that was last changed before that. When that read fails too, what is here
   * stays as it was: it is no longer owed to anybody, so it is stale rather
   * than lost, and any later change to it brings it back in step.
   *
   * @param set {ScoreSet}
   * @param action {string}
   * @param error {SetsApiError}
   * @return {Promise<void>}
   * @private
   */
  async _giveUpOn(set, action, error) {
    let fromApi = null;
    try {
      const accessToken = await this._oidc.getActiveAccessToken();
      fromApi = accessToken == null ? null : await this._api.getSet(set.id, accessToken);
    } catch (readError) {
      console.error(`failed to read set ${set.id} back after giving up on it`, readError);
      await this._store([_synced(set, set.last_synced_at)]);
      this._reportSyncProblem({setId: set.id, title: set.title, action, error});
      return;
    }

    if (fromApi == null) {
      // There is no such set for this user: whatever was written here is a set
      // that does not exist, and a headstone is what that looks like.
      await this._store([new ScoreSet(
        set.id,
        set.title,
        set.description,
        set.entries,
        set.shared_with,
        set.is_owner,
        set.last_changed_at,
        set.deleted_at ?? new Date(),
        set.last_synced_at,
        PendingChange.None)]);
    } else {
      await this._store([_setFromApi(fromApi, new Date())]);
    }

    this._reportSyncProblem({setId: set.id, title: set.title, action, error});
  }

  /**
   * Reads in everything that changed on the server since the last time it said
   * anything, the sets that were deleted there included.
   *
   * @return {Promise<void>}
   * @private
   */
  async _pull() {
    const accessToken = await this._oidc.getActiveAccessToken();
    const fromApi = await this._api.listSets(this._lastSyncedAt(), new Date(), accessToken);
    if (fromApi.length === 0) {
      return;
    }

    const syncedAt = new Date();
    const toStore = [];
    for (const dto of fromApi) {
      const existing = this._sets.get(dto.id);
      // A set that still owes the server a write was written here after the
      // last thing the server told us, so it is the newer of the two and the
      // answer is out of date the moment it arrives.
      if (existing?.pending_change != null) {
        continue;
      }
      // What has been written here and not sent yet is newer than the answer
      // for the same reason, and is kept on top of it; the rest of what the
      // server says is taken as it stands.
      toStore.push(_carryPending(_setFromApi(dto, syncedAt), existing));
    }

    await this._store(toStore);
  }

  /**
   * The last moment the server said anything about a set, which is where the
   * next change window starts. `null` when it has never said anything, which
   * asks about everything there has ever been.
   *
   * @return {Date|null}
   * @private
   */
  _lastSyncedAt() {
    let latest = null;
    for (const set of this._sets.values()) {
      if (set.last_synced_at != null && (latest == null || set.last_synced_at > latest)) {
        latest = set.last_synced_at;
      }
    }
    return latest;
  }

  /**
   * @param sets {ScoreSet[]}
   * @return {Promise<void>}
   * @private
   */
  async _store(sets) {
    if (sets.length === 0) {
      return;
    }
    for (const set of sets) {
      this._sets.set(set.id, set);
    }
    await this._database.saveSets(sets);
    this._notifySetsChangesListeners();
  }

  // --------------------------------------------------------------------------
  // LISTENERS
  // --------------------------------------------------------------------------

  /** @param listener {SetsChangedCallback} */
  addSetsChangesListener(listener) {
    this._setsChangesListeners.push(listener);
  }

  /** @param listener {SyncProblemCallback} */
  addSyncProblemListener(listener) {
    this._syncProblemListeners.push(listener);
  }

  _notifySetsChangesListeners() {
    for (const listener of this._setsChangesListeners) {
      listener();
    }
  }

  /**
   * @param problem {SyncProblem}
   * @private
   */
  _reportSyncProblem(problem) {
    for (const listener of this._syncProblemListeners) {
      listener(problem);
    }
  }
}

// ----------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------

/**
 * A set the way the API hands it over, as one this app keeps: the moments as
 * dates rather than as the strings they arrive as, and nothing owed.
 *
 * @param dto {import("./api.js").SetDto}
 * @param syncedAt {Date}
 * @return {ScoreSet}
 * @private
 */
function _setFromApi(dto, syncedAt) {
  return new ScoreSet(
    dto.id,
    dto.title ?? '',
    dto.description ?? '',
    (dto.entries ?? []).map((entry) => _entryOf(entry)),
    dto.shared_with ?? [],
    dto.is_owner === true,
    dto.last_changed_at == null ? new Date(0) : new Date(dto.last_changed_at),
    dto.deleted_at == null ? null : new Date(dto.deleted_at),
    syncedAt,
    PendingChange.None,
    []);
}

/**
 * The set the server just described, with what this device has written and not
 * sent put back on top of it.
 *
 * Anything still owed was written after the last thing the server said about
 * it, so it is the newer of the two. That is the running order as a whole while
 * a song is waiting to be sent — the answer cannot know about the song, and
 * half a running order is not one — and the view of any entry that is waiting.
 *
 * @param incoming {ScoreSet} as the server has it
 * @param existing {ScoreSet|null|undefined} as this device has it
 * @return {ScoreSet}
 * @private
 */
function _carryPending(incoming, existing) {
  if (existing == null) {
    return incoming;
  }

  const owedEntries = existing.pending_entries ?? [];
  const entries = owedEntries.length > 0 ? existing.entries : incoming.entries;
  const owedViews = _keptOf(existing.pending_views, entries);

  return new ScoreSet(
    incoming.id,
    incoming.title,
    incoming.description,
    entries.map((entry) => {
      if (!owedViews.includes(entry.id)) {
        return entry;
      }
      const written = existing.entries.find((candidate) => candidate.id === entry.id);
      return new SetEntry(
        entry.id,
        entry.score_id,
        entry.description,
        entry.transposition,
        _viewOf(written.view),
        entry.synced);
    }),
    incoming.shared_with,
    incoming.is_owner,
    incoming.last_changed_at,
    incoming.deleted_at,
    incoming.last_synced_at,
    incoming.pending_change,
    owedViews,
    owedEntries);
}

/**
 * The same set with a different running order, and a different idea of what is
 * owed about it.
 *
 * @param set {ScoreSet}
 * @param entries {SetEntry[]}
 * @param pendingEntries {{id: string, action: string}[]}
 * @return {ScoreSet}
 * @private
 */
function _withEntries(set, entries, pendingEntries) {
  return new ScoreSet(
    set.id,
    set.title,
    set.description,
    entries,
    set.shared_with,
    set.is_owner,
    set.last_changed_at,
    set.deleted_at,
    set.last_synced_at,
    set.pending_change,
    _keptOf(set.pending_views, entries),
    pendingEntries);
}

/**
 * The same set with one entry as the server now has it, and nothing left owed
 * about that entry.
 *
 * The place it came back in is where it went: the server closes the set up
 * around an entry, so writing one can move the others.
 *
 * @param set {ScoreSet}
 * @param dto {import("./api.js").SetEntryDto}
 * @return {ScoreSet}
 * @private
 */
function _withStoredEntry(set, dto) {
  const stored = _entryOf(dto);
  const others = set.entries.filter((entry) => entry.id !== stored.id);
  const position = Math.min(Math.max(dto.position ?? others.length, 0), others.length);

  // Its own view is the one this device has: the answer carries the view the
  // server knew about, which is older than one that is still waiting to be
  // sent.
  const here = set.entries.find((entry) => entry.id === stored.id);
  if (here != null && set.pending_views.includes(stored.id)) {
    stored.view = _viewOf(here.view);
  }

  return _withEntries(
    set,
    [...others.slice(0, position), stored, ...others.slice(position)],
    _withoutOwed(set.pending_entries, stored.id));
}

/**
 * The same set with nothing left owed about one entry.
 *
 * @param set {ScoreSet}
 * @param entryId {string}
 * @return {ScoreSet}
 * @private
 */
function _withoutPendingEntry(set, entryId) {
  return _withEntries(set, set.entries, _withoutOwed(set.pending_entries, entryId));
}

/**
 * What is owed about the entries of a set, with one entry now owing this.
 *
 * An entry is owed once however often it is written: what goes out is the entry
 * as it now reads, not every edit that was made to it. The last thing said
 * about it is what is said, so a write that follows a delete replaces it.
 *
 * @param owed {{id: string, action: string}[]}
 * @param entryId {string}
 * @param action {string}
 * @return {{id: string, action: string}[]}
 * @private
 */
function _owing(owed, entryId, action) {
  return [..._withoutOwed(owed, entryId), {id: entryId, action: action}];
}

/**
 * @param owed {{id: string, action: string}[]}
 * @param entryId {string}
 * @return {{id: string, action: string}[]}
 * @private
 */
function _withoutOwed(owed, entryId) {
  return (owed ?? []).filter((entry) => entry.id !== entryId);
}

/**
 * The same set with one entry looked at differently, and that entry marked as
 * owed to the server or no longer owed.
 *
 * @param set {ScoreSet}
 * @param entryId {string}
 * @param view {EntryView}
 * @param owed {boolean}
 * @return {ScoreSet}
 * @private
 */
function _withEntryView(set, entryId, view, owed) {
  const pending = set.pending_views.filter((id) => id !== entryId);
  if (owed) {
    pending.push(entryId);
  }

  return new ScoreSet(
    set.id,
    set.title,
    set.description,
    set.entries.map((entry) => entry.id !== entryId ? entry : new SetEntry(
      entry.id,
      entry.score_id,
      entry.description,
      entry.transposition,
      view,
      entry.synced)),
    set.shared_with,
    set.is_owner,
    set.last_changed_at,
    set.deleted_at,
    set.last_synced_at,
    set.pending_change,
    pending,
    set.pending_entries);
}

/**
 * The same set with nothing left to say about one entry.
 *
 * @param set {ScoreSet}
 * @param entryId {string}
 * @return {ScoreSet}
 * @private
 */
function _withoutPendingView(set, entryId) {
  return new ScoreSet(
    set.id,
    set.title,
    set.description,
    set.entries,
    set.shared_with,
    set.is_owner,
    set.last_changed_at,
    set.deleted_at,
    set.last_synced_at,
    set.pending_change,
    set.pending_views.filter((id) => id !== entryId),
    set.pending_entries);
}

/**
 * The entry ids of `owed` that the given entries still have. A view of an entry
 * that is no longer in the set is about a song that is no longer played.
 *
 * @param owed {string[]|null|undefined}
 * @param entries {SetEntry[]}
 * @return {string[]}
 * @private
 */
function _keptOf(owed, entries) {
  if (owed == null || owed.length === 0) {
    return [];
  }
  return owed.filter((id) => entries.some((entry) => entry.id === id));
}

/**
 * The same set, with nothing left owed to the server.
 *
 * @param set {ScoreSet}
 * @param syncedAt {Date|null}
 * @return {ScoreSet}
 * @private
 */
function _synced(set, syncedAt) {
  return new ScoreSet(
    set.id,
    set.title,
    set.description,
    set.entries,
    set.shared_with,
    set.is_owner,
    set.last_changed_at,
    set.deleted_at,
    syncedAt,
    PendingChange.None,
    set.pending_views,
    set.pending_entries);
}

/**
 * A set as the API reads it: what the gig is, and who may read it. What is
 * played in it is written an entry at a time and is not stated here.
 *
 * @param set {ScoreSet}
 * @return {WriteSetDto}
 * @private
 */
function _writeSetOf(set) {
  return new WriteSetDto(set.title, set.description, [...set.shared_with]);
}

/**
 * One entry, with everything the API insists on filled in: it asks for all of
 * them, and an entry that came from a form has only what was typed into it.
 *
 * @param entry {Object}
 * @return {SetEntry}
 * @private
 */
function _entryOf(entry) {
  return new SetEntry(
    // An entry that has not been named yet is named here rather than by the
    // server. It is what a view of it points at, and a player who adds a song
    // at a gig and says how they read it has to be able to say both before
    // either has been sent anywhere.
    entry.id ?? crypto.randomUUID(),
    entry.score_id,
    entry.description ?? '',
    _transpositionOf(entry.transposition),
    _viewOf(entry.view),
    // Everything the API hands over is on the server by definition.
    true);
}

/**
 * How somebody looks at one entry, with everything filled in. An entry nobody
 * has looked at differently has the view every entry starts with: as written,
 * every part on screen.
 *
 * @param view {Object|null|undefined}
 * @return {EntryView}
 * @private
 */
function _viewOf(view) {
  return new EntryView(
    _transpositionOf(view?.transposition),
    Array.isArray(view?.hidden_parts) ? [...view.hidden_parts] : []);
}

/**
 * A transposition the API will take: a whole number of semitones, within the
 * octave either way that the player offers.
 *
 * @param semitones {*}
 * @return {number}
 * @private
 */
function _transpositionOf(semitones) {
  const asNumber = Number(semitones);
  if (!Number.isFinite(asNumber)) {
    return 0;
  }
  return Math.min(MAX_TRANSPOSITION, Math.max(MIN_TRANSPOSITION, Math.round(asNumber)));
}

/**
 * The addresses a set is shared with, as the API compares them: in lower case,
 * each of them once. Whether they are addresses at all is the server's to say —
 * it refuses anything that is not one rather than tidying it up, and a share
 * that was going to go nowhere is better said so than quietly dropped here.
 *
 * @param addresses {string[]}
 * @return {string[]}
 * @private
 */
function _addressesOf(addresses) {
  const seen = [];
  for (const address of addresses) {
    const trimmed = `${address}`.trim().toLowerCase();
    if (trimmed !== '' && !seen.includes(trimmed)) {
      seen.push(trimmed);
    }
  }
  return seen;
}

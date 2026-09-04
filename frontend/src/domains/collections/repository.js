import {Collection, CollectionDatabase, CollectionEntry, EntryView, PendingChange} from "./database.js";
import {
  CollectionsApi,
  CollectionsApiError,
  WriteCollectionDto,
  WriteCollectionEntryDto,
  WriteEntryViewDto,
} from "./api.js";
import {OidcApi} from "../auth/oidc-api.js";
import {MAX_TRANSPOSITION, MIN_TRANSPOSITION} from "../scores/score-view.js";
import {clampZoom} from "../scores/pinch-zoom.js";

/**
 * The piece is already in the collection.
 *
 * It is the one refusal that is worth acting on rather than reporting: what the
 * caller wanted was the piece to be in the book, and it is. What it is in is
 * {@link entryId}, so a page can point at it instead of saying no.
 */
export class ScoreAlreadyInCollectionError extends Error {
  /**
   * @param scoreId {string}
   * @param entryId {string} the entry the score is already in
   */
  constructor(scoreId, entryId) {
    super(`Score '${scoreId}' is already in this collection, as entry '${entryId}'.`);
    this.name = 'ScoreAlreadyInCollectionError';
    this.scoreId = scoreId;
    this.entryId = entryId;
  }
}

/**
 * The collections, as this device has them.
 *
 * A collection is written here first and sent afterwards, for the same reason a
 * set is: a player adds a piece to the book where the book is, which is where
 * there is no network. Every edit is therefore stored locally, marked as owed
 * to the server, and pushed the first time the server can be reached — at the
 * end of the edit if that is right away, and at the next sync otherwise.
 *
 * What that costs is that this device and the server can disagree, and the rule
 * for that is: what was written here wins until it has been pushed. A
 * collection with an edit still owed is never overwritten by what a sync brings
 * in, because that edit is the newer of the two by definition.
 *
 * The one rule that is a collection's own is that a score is in it at most
 * once. It is held here as well as on the server, because a player who is
 * offline should be told they already have a piece at the moment they add it
 * rather than at the next sync.
 *
 * The entries are kept in whatever order they arrived in, which is by title
 * from the server and at the end for anything added here. A collection has no
 * order of its own and this is not one: what a piece is called is in the score
 * rather than in the entry, so a list is sorted where the titles are, which is
 * the page.
 *
 * @typedef {function()} CollectionsChangedCallback
 * @typedef {{collectionId: string, title: string, action: string, error: CollectionsApiError}} SyncProblem
 * @typedef {function(SyncProblem)} SyncProblemCallback
 */
export class CollectionsRepository {
  /**
   * @param database {CollectionDatabase}
   * @param api {CollectionsApi}
   * @param oidc {OidcApi}
   */
  constructor(database, api, oidc) {
    this._database = database;
    this._api = api;
    this._oidc = oidc;
  }

  /**
   * Every collection that is kept here, the deleted ones included.
   *
   * @type {Map<string, Collection>}
   * @private
   */
  _collections = new Map();

  /**
   * @type {CollectionsChangedCallback[]}
   * @private
   */
  _collectionsChangesListeners = [];

  /**
   * @type {SyncProblemCallback[]}
   * @private
   */
  _syncProblemListeners = [];

  /**
   * The collections there are, most recently changed first. The deleted ones
   * are kept but are no longer collections anyone has.
   *
   * @return {Collection[]}
   */
  get collections() {
    return Array.from(this._collections.values())
      .filter((collection) => collection.deleted_at == null)
      .sort((a, b) => (b.last_changed_at?.getTime() ?? 0) - (a.last_changed_at?.getTime() ?? 0));
  }

  /**
   * @param collectionId {string}
   * @return {Collection|null}
   */
  getCollection(collectionId) {
    const collection = this._collections.get(collectionId);
    if (collection == null || collection.deleted_at != null) {
      return null;
    }
    return collection;
  }

  /**
   * The collections a score is in, most recently changed first.
   *
   * This is the question a collection exists to answer: a player who has a
   * piece on screen wants to know which book it came out of and what else is in
   * that book with it.
   *
   * @param scoreId {string}
   * @return {Collection[]}
   */
  collectionsWith(scoreId) {
    return this.collections.filter((collection) =>
      collection.entries.some((entry) => entry.score_id === scoreId));
  }

  /** @return {boolean} whether anything here is still owed to the server */
  get hasPendingChanges() {
    return Array.from(this._collections.values()).some((collection) =>
      collection.pending_change != null
      || collection.pending_entries?.length > 0
      || collection.pending_views?.length > 0);
  }

  async init() {
    const collections = await this._database.fetchCollections();
    for (const collection of collections) {
      this._collections.set(collection.id, collection);
    }
  }

  // --------------------------------------------------------------------------
  // WRITING
  // --------------------------------------------------------------------------

  /**
   * Stores what a collection is — the group of pieces, and who may read it —
   * and hands it back.
   *
   * What is in it is not touched: an entry is written on its own, so correcting
   * a title is correcting a title. A collection that is created here is created
   * empty and filled afterwards, the same way it is on the server.
   *
   * @param draft {{id?: string, title: string, description?: string,
   *   shared_with?: string[]}}
   * @return {Promise<Collection>}
   */
  async saveCollection(draft) {
    const id = draft.id ?? crypto.randomUUID();
    const existing = this._collections.get(id);
    if (existing != null && existing.is_owner === false) {
      throw new Error(
        `Collection with id '${id}' belongs to someone else and cannot be changed.`);
    }

    const collection = new Collection(
      id,
      draft.title ?? '',
      draft.description ?? '',
      existing?.entries ?? [],
      _addressesOf(draft.shared_with ?? []),
      existing?.is_owner ?? true,
      new Date(),
      // Writing a collection that had been deleted brings it back: a client
      // that still has it and edits it is saying it should exist.
      null,
      existing?.last_synced_at ?? null,
      PendingChange.Write,
      existing?.pending_views ?? [],
      existing?.pending_entries ?? []);

    await this._store([collection]);
    await this._pushIfPossible(id);
    return this._collections.get(id);
  }

  /**
   * Puts one piece into a collection, or changes what the group does with it,
   * and hands the collection back as it now reads.
   *
   * A collection holds a piece once. Adding a score the collection already has
   * is {@link ScoreAlreadyInCollectionError}, which names the entry it is
   * already in — the caller wanted the piece to be in the book, and it is, so
   * what to do with that is the page's to decide rather than a write to make
   * twice. Writing the entry a score is already in is not that: it is saying
   * what the group does with a piece that is in the collection.
   *
   * The pieces with no score are outside the rule: they are told apart by what
   * is written next to them, and two lines of a book nobody has scanned are two
   * pieces. Which is why one of those has to be called something — a piece with
   * no score and no name cannot be found, sorted, or told from the next one, so
   * it is refused here rather than queued for a server that will refuse it too.
   *
   * @param collectionId {string}
   * @param entry {{id?: string, score_id?: string|null, description?: string,
   *   transposition?: number}}
   * @return {Promise<Collection>}
   */
  async saveEntry(collectionId, entry) {
    const existing = this._ownedCollection(collectionId);

    const entryId = entry.id ?? crypto.randomUUID();
    const known = existing.entries.find((candidate) => candidate.id === entryId);
    const scoreId = _scoreIdOf('score_id' in entry ? entry.score_id : known?.score_id);
    const description = entry.description ?? known?.description ?? '';

    const alreadyIn = scoreId == null ? null : existing.entries.find((candidate) =>
      candidate.id !== entryId && candidate.score_id === scoreId);
    if (alreadyIn != null) {
      throw new ScoreAlreadyInCollectionError(scoreId, alreadyIn.id);
    }

    if (scoreId == null && `${description}`.trim() === '') {
      throw new Error(
        'A piece with no score has nothing to be called by but what is written next to it.');
    }

    const written = new CollectionEntry(
      entryId,
      // Which piece it is is asked for by name rather than by whether it is
      // filled in: `null` is a piece that is in the collection but not in here,
      // and reading that as nothing said would put the score back on an entry
      // somebody has just said has none.
      scoreId,
      description,
      _transpositionOf(entry.transposition ?? known?.transposition),
      // How this user reads it is theirs and is written on its own, so an entry
      // that is renamed keeps it.
      known?.view ?? new EntryView(),
      known?.synced ?? false);

    const others = existing.entries.filter((candidate) => candidate.id !== entryId);
    // A piece that is already in the collection stays where it is in the list,
    // and a new one goes on the end. Neither says anything: a collection has no
    // order, and where a page draws a piece is where its title puts it.
    const entries = known == null
      ? [...others, written]
      : existing.entries.map((candidate) => candidate.id === entryId ? written : candidate);

    await this._store([_withEntries(
      existing,
      entries,
      _owing(existing.pending_entries, entryId, PendingChange.Write))]);
    await this._pushIfPossible(collectionId);
    return this._collections.get(collectionId);
  }

  /**
   * Takes one piece out of a collection.
   *
   * What every player said about how they look at it goes with it: it was about
   * a piece that is no longer in the collection.
   *
   * @param collectionId {string}
   * @param entryId {string}
   * @return {Promise<Collection>}
   */
  async deleteEntry(collectionId, entryId) {
    const existing = this._ownedCollection(collectionId);
    const entry = existing.entries.find((candidate) => candidate.id === entryId);
    if (entry == null) {
      return existing;
    }

    // An entry the server never heard of is nothing to tell it about: there is
    // no row there to remove, and whatever was queued about it is about a piece
    // that was never in any book but this one.
    const owing = entry.synced
      ? _owing(existing.pending_entries, entryId, PendingChange.Delete)
      : existing.pending_entries.filter((owed) => owed.id !== entryId);

    await this._store([_withEntries(
      existing,
      existing.entries.filter((candidate) => candidate.id !== entryId),
      owing)]);
    await this._pushIfPossible(collectionId);
    return this._collections.get(collectionId);
  }

  /**
   * The collection with the given id, when it is this user's to fill.
   *
   * @param collectionId {string}
   * @return {Collection}
   * @private
   */
  _ownedCollection(collectionId) {
    const collection = this._collections.get(collectionId);
    if (collection == null || collection.deleted_at != null) {
      throw new Error(`Collection with id '${collectionId}' is not on this device.`);
    }
    if (collection.is_owner === false) {
      throw new Error(
        `Collection with id '${collectionId}' belongs to someone else and cannot be changed.`);
    }
    return collection;
  }

  /**
   * Stores how this user looks at one entry, and tells the server as soon as it
   * can.
   *
   * This is not writing the collection, and it is deliberately not asked to be
   * the owner of one: a view says nothing about the collection and changes
   * nothing anybody else sees, so a player who cannot add a piece to the book
   * can still say what key they read one in and which parts they want on
   * screen.
   *
   * @param collectionId {string}
   * @param entryId {string}
   * @param view {{transposition?: number, hidden_parts?: string[],
   *   zoom?: number}}
   * @return {Promise<Collection>}
   */
  async saveEntryView(collectionId, entryId, view) {
    const existing = this._collections.get(collectionId);
    if (existing == null || existing.deleted_at != null) {
      throw new Error(`Collection with id '${collectionId}' is not on this device.`);
    }
    if (!existing.entries.some((entry) => entry.id === entryId)) {
      throw new Error(`Collection '${collectionId}' has no entry '${entryId}'.`);
    }

    await this._store([_withEntryView(existing, entryId, _viewOf(view), true)]);
    await this._pushIfPossible(collectionId);
    return this._collections.get(collectionId);
  }

  /**
   * Marks the collection as deleted here, and tells the server as soon as it
   * can.
   *
   * It is kept rather than dropped, the same way the server keeps it: a sync
   * only asks about what changed since the last one, so a collection that was
   * simply forgotten here would be fetched straight back in as something new.
   *
   * @param collectionId {string}
   * @return {Promise<void>}
   */
  async deleteCollection(collectionId) {
    const existing = this._collections.get(collectionId);
    if (existing == null || existing.deleted_at != null) {
      return;
    }
    if (existing.is_owner === false) {
      throw new Error(
        `Collection with id '${collectionId}' belongs to someone else and cannot be deleted.`);
    }

    const now = new Date();
    const deleted = new Collection(
      existing.id,
      existing.title,
      existing.description,
      existing.entries,
      existing.shared_with,
      existing.is_owner,
      now,
      now,
      existing.last_synced_at,
      // A collection the server never heard of is nothing to tell it about:
      // there is no row there to mark as gone, and the headstone here is
      // enough.
      existing.last_synced_at == null ? PendingChange.None : PendingChange.Delete,
      // How anybody read a collection that is gone is not worth a request.
      []);

    await this._store([deleted]);
    await this._pushIfPossible(collectionId);
  }

  // --------------------------------------------------------------------------
  // SYNCING
  // --------------------------------------------------------------------------

  /**
   * Squares what is here with what is on the server: what was written here goes
   * out first, so that a collection that has just been pushed is not read back
   * as it was before the push, and what the server has changed since the last
   * sync comes in after.
   *
   * @return {Promise<void>}
   */
  async syncWithApi() {
    console.log('syncing api collections with local collections');
    await this._pushPending();
    await this._pull();
  }

  /**
   * Sends everything that is still owed to the server.
   *
   * One collection failing does not stop the others: they are separate writes
   * and there is no reason one that can be stored should wait for one that
   * cannot.
   *
   * @return {Promise<void>}
   * @private
   */
  async _pushPending() {
    const owing = Array.from(this._collections.values()).filter((collection) =>
      collection.pending_change != null
      || collection.pending_entries.length > 0
      || collection.pending_views.length > 0);
    for (const collection of owing) {
      await this._push(collection.id);
    }
  }

  /**
   * Pushes one collection if there is anything to push and anything to push it
   * to.
   *
   * @param collectionId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushIfPossible(collectionId) {
    const collection = this._collections.get(collectionId);
    if (collection == null
      || (collection.pending_change == null
        && collection.pending_entries.length === 0
        && collection.pending_views.length === 0)) {
      return;
    }
    if (!await this._api.canBeReached() || !await this._oidc.canBeReached()) {
      console.log('the api cannot be reached; what was written stays queued');
      return;
    }
    await this._push(collectionId);
  }

  /**
   * Sends what is owed for one collection and squares what is here with the
   * answer.
   *
   * This never throws. A push that failed for a reason that may pass is left
   * queued for the next sync; one the server will refuse just as firmly next
   * time is given up on, the collection is read back the way the server has it,
   * and the problem is reported — an edit that is quietly dropped is worse than
   * one that is dropped loudly.
   *
   * @param collectionId {string}
   * @return {Promise<void>}
   * @private
   */
  async _push(collectionId) {
    const collection = this._collections.get(collectionId);
    if (collection == null) {
      return;
    }

    if (collection.pending_change != null) {
      await this._pushCollection(collectionId);
    }
    // In that order, because each of them is written against the one before it:
    // an entry is written against a collection, and a view against an entry. A
    // collection the server has not been told about is nothing to hang an entry
    // off, and an entry it has not been told about is nothing to hang a view
    // off — so whatever did not get through keeps what depends on it queued
    // behind it.
    if (this._collections.get(collectionId)?.pending_change != null) {
      return;
    }
    await this._pushEntries(collectionId);
    await this._pushViews(collectionId);
  }

  /**
   * Sends what has been put into the collection here and what has been taken
   * out, one piece at a time and in the order it was done.
   *
   * One entry failing stops neither the others nor the views: they are separate
   * writes about separate pieces.
   *
   * @param collectionId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushEntries(collectionId) {
    const owed = this._collections.get(collectionId)?.pending_entries ?? [];
    for (const {id: entryId, action} of [...owed]) {
      const collection = this._collections.get(collectionId);
      if (collection == null) {
        return;
      }

      const entry = collection.entries.find((candidate) => candidate.id === entryId);
      if (action === PendingChange.Write && entry == null) {
        // It was taken out again before this ever went; there is nothing left
        // to write.
        await this._store([_withoutPendingEntry(collection, entryId)]);
        continue;
      }

      try {
        const accessToken = await this._oidc.getActiveAccessToken();
        if (accessToken == null) {
          return;
        }

        if (action === PendingChange.Delete) {
          await this._api.deleteEntry(collectionId, entryId, accessToken);
          await this._store([
            _withoutPendingEntry(this._collections.get(collectionId), entryId)]);
          continue;
        }

        const stored = await this._api.putEntry(collectionId, entryId, accessToken,
          new WriteCollectionEntryDto(entry.score_id, entry.description, entry.transposition));
        await this._store([_withStoredEntry(this._collections.get(collectionId), stored)]);
      } catch (error) {
        // The collection already holds the piece. That is somebody having added
        // it on another device while this one was offline, and the answer is
        // not to keep asking or to keep two of it: the piece is in the book,
        // which is what was wanted, so this second copy of it goes and the one
        // that is already there stays.
        if (error instanceof CollectionsApiError && error.isAlreadyInTheCollection) {
          console.warn(
            `the collection already holds the score of entry ${entryId}; dropping this copy of it`,
            error);
          const current = this._collections.get(collectionId);
          await this._store([_withEntries(
            current,
            current.entries.filter((candidate) => candidate.id !== entryId),
            _withoutOwed(current.pending_entries, entryId))]);
          continue;
        }

        if (!(error instanceof CollectionsApiError) || error.isWorthRetrying) {
          console.error(`failed to ${action} entry ${entryId}; it stays queued`, error);
          continue;
        }

        console.error(`the server refused to ${action} entry ${entryId}; giving up on it`, error);
        const current = this._collections.get(collectionId);
        await this._store([_withoutPendingEntry(current, entryId)]);
        this._reportSyncProblem({
          collectionId: collectionId,
          title: current?.title ?? '',
          action: `entry ${action}`,
          error: error,
        });
      }
    }
  }

  /**
   * @param collectionId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushCollection(collectionId) {
    const collection = this._collections.get(collectionId);
    const action = collection.pending_change;
    try {
      const accessToken = await this._oidc.getActiveAccessToken();
      if (accessToken == null) {
        return;
      }

      if (action === PendingChange.Delete) {
        await this._api.deleteCollection(collection.id, accessToken);
        await this._store([_synced(collection, new Date())]);
        return;
      }

      const stored = await this._api.putCollection(
        collection.id, accessToken, _writeCollectionOf(collection));
      // What comes back is the collection as the server has it, which is the
      // truth about what a collection is — but not about what has been done to
      // it here and not sent yet, which is newer than anything the server can
      // say.
      await this._store([_carryPending(_collectionFromApi(stored, new Date()), collection)]);
    } catch (error) {
      if (!(error instanceof CollectionsApiError) || error.isWorthRetrying) {
        console.error(`failed to ${action} collection ${collection.id}; it stays queued`, error);
        return;
      }

      console.error(
        `the server refused to ${action} collection ${collection.id}; giving up on it`, error);
      await this._giveUpOn(collection, action, error);
    }
  }

  /**
   * Sends how this user reads the entries they have said something about.
   *
   * Each entry is its own write, and one that fails stops neither the others
   * nor the collection it is in: they are separate things said about separate
   * pieces.
   *
   * @param collectionId {string}
   * @return {Promise<void>}
   * @private
   */
  async _pushViews(collectionId) {
    const owed = this._collections.get(collectionId)?.pending_views ?? [];
    for (const entryId of [...owed]) {
      const collection = this._collections.get(collectionId);
      const entry = collection?.entries.find((candidate) => candidate.id === entryId);
      if (collection == null || entry == null) {
        // The entry is no longer in the collection, so how it was read is not
        // about anything any more.
        if (collection != null) {
          await this._store([_withoutPendingView(collection, entryId)]);
        }
        continue;
      }

      // The entry itself is still owed, so the server has nothing to hang this
      // on yet. It waits for the piece, the way the piece waits for the
      // collection.
      if (collection.pending_entries.some((owed) => owed.id === entryId)) {
        continue;
      }

      try {
        const accessToken = await this._oidc.getActiveAccessToken();
        if (accessToken == null) {
          return;
        }

        const stored = await this._api.putEntryView(collectionId, entryId, accessToken,
          new WriteEntryViewDto(
            entry.view.transposition,
            [...entry.view.hidden_parts],
            entry.view.zoom));
        await this._store([
          _withEntryView(this._collections.get(collectionId), entryId, _viewOf(stored), false)]);
      } catch (error) {
        if (!(error instanceof CollectionsApiError) || error.isWorthRetrying) {
          console.error(`failed to save the view of entry ${entryId}; it stays queued`, error);
          continue;
        }

        console.error(`the server refused the view of entry ${entryId}; giving up on it`, error);
        const collection = this._collections.get(collectionId);
        await this._store([_withoutPendingView(collection, entryId)]);
        this._reportSyncProblem({
          collectionId: collectionId,
          title: collection?.title ?? '',
          action: 'view',
          error: error,
        });
      }
    }
  }

  /**
   * Takes back an edit the server will not have, and reports it.
   *
   * The collection is read back by its id rather than left to the next sync,
   * which only asks about what changed since the last one and would not cover
   * one that was last changed before that. When that read fails too, what is
   * here stays as it was: it is no longer owed to anybody, so it is stale
   * rather than lost, and any later change to it brings it back in step.
   *
   * @param collection {Collection}
   * @param action {string}
   * @param error {CollectionsApiError}
   * @return {Promise<void>}
   * @private
   */
  async _giveUpOn(collection, action, error) {
    let fromApi = null;
    try {
      const accessToken = await this._oidc.getActiveAccessToken();
      fromApi = accessToken == null
        ? null
        : await this._api.getCollection(collection.id, accessToken);
    } catch (readError) {
      console.error(
        `failed to read collection ${collection.id} back after giving up on it`, readError);
      await this._store([_synced(collection, collection.last_synced_at)]);
      this._reportSyncProblem(
        {collectionId: collection.id, title: collection.title, action, error});
      return;
    }

    if (fromApi == null) {
      // There is no such collection for this user: whatever was written here is
      // a collection that does not exist, and a headstone is what that looks
      // like.
      await this._store([new Collection(
        collection.id,
        collection.title,
        collection.description,
        collection.entries,
        collection.shared_with,
        collection.is_owner,
        collection.last_changed_at,
        collection.deleted_at ?? new Date(),
        collection.last_synced_at,
        PendingChange.None)]);
    } else {
      await this._store([_collectionFromApi(fromApi, new Date())]);
    }

    this._reportSyncProblem({collectionId: collection.id, title: collection.title, action, error});
  }

  /**
   * Reads in everything that changed on the server since the last time it said
   * anything, the collections that were deleted there included.
   *
   * @return {Promise<void>}
   * @private
   */
  async _pull() {
    const accessToken = await this._oidc.getActiveAccessToken();
    const fromApi = await this._api.listCollections(
      this._lastSyncedAt(), new Date(), accessToken);
    if (fromApi.length === 0) {
      return;
    }

    const syncedAt = new Date();
    const toStore = [];
    for (const dto of fromApi) {
      const existing = this._collections.get(dto.id);
      // A collection that still owes the server a write was written here after
      // the last thing the server told us, so it is the newer of the two and
      // the answer is out of date the moment it arrives.
      if (existing?.pending_change != null) {
        continue;
      }
      // What has been written here and not sent yet is newer than the answer
      // for the same reason, and is kept on top of it; the rest of what the
      // server says is taken as it stands.
      toStore.push(_carryPending(_collectionFromApi(dto, syncedAt), existing));
    }

    await this._store(toStore);
  }

  /**
   * The last moment the server said anything about a collection, which is where
   * the next change window starts. `null` when it has never said anything,
   * which asks about everything there has ever been.
   *
   * @return {Date|null}
   * @private
   */
  _lastSyncedAt() {
    let latest = null;
    for (const collection of this._collections.values()) {
      if (collection.last_synced_at != null
        && (latest == null || collection.last_synced_at > latest)) {
        latest = collection.last_synced_at;
      }
    }
    return latest;
  }

  /**
   * @param collections {Collection[]}
   * @return {Promise<void>}
   * @private
   */
  async _store(collections) {
    if (collections.length === 0) {
      return;
    }
    for (const collection of collections) {
      this._collections.set(collection.id, collection);
    }
    await this._database.saveCollections(collections);
    this._notifyCollectionsChangesListeners();
  }

  // --------------------------------------------------------------------------
  // LISTENERS
  // --------------------------------------------------------------------------

  /** @param listener {CollectionsChangedCallback} */
  addCollectionsChangesListener(listener) {
    this._collectionsChangesListeners.push(listener);
  }

  /** @param listener {SyncProblemCallback} */
  addSyncProblemListener(listener) {
    this._syncProblemListeners.push(listener);
  }

  _notifyCollectionsChangesListeners() {
    for (const listener of this._collectionsChangesListeners) {
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
 * A collection the way the API hands it over, as one this app keeps: the
 * moments as dates rather than as the strings they arrive as, and nothing owed.
 *
 * @param dto {import("./api.js").CollectionDto}
 * @param syncedAt {Date}
 * @return {Collection}
 * @private
 */
function _collectionFromApi(dto, syncedAt) {
  return new Collection(
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
 * The collection the server just described, with what this device has written
 * and not sent put back on top of it.
 *
 * Anything still owed was written after the last thing the server said about
 * it, so it is the newer of the two. That is what is in the collection as a
 * whole while a piece is waiting to be sent — the answer cannot know about the
 * piece — and the view of any entry that is waiting.
 *
 * @param incoming {Collection} as the server has it
 * @param existing {Collection|null|undefined} as this device has it
 * @return {Collection}
 * @private
 */
function _carryPending(incoming, existing) {
  if (existing == null) {
    return incoming;
  }

  const owedEntries = existing.pending_entries ?? [];
  const entries = owedEntries.length > 0 ? existing.entries : incoming.entries;
  const owedViews = _keptOf(existing.pending_views, entries);

  return new Collection(
    incoming.id,
    incoming.title,
    incoming.description,
    entries.map((entry) => {
      if (!owedViews.includes(entry.id)) {
        return entry;
      }
      const written = existing.entries.find((candidate) => candidate.id === entry.id);
      return new CollectionEntry(
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
 * The same collection holding different pieces, and with a different idea of
 * what is owed about them.
 *
 * @param collection {Collection}
 * @param entries {CollectionEntry[]}
 * @param pendingEntries {{id: string, action: string}[]}
 * @return {Collection}
 * @private
 */
function _withEntries(collection, entries, pendingEntries) {
  return new Collection(
    collection.id,
    collection.title,
    collection.description,
    entries,
    collection.shared_with,
    collection.is_owner,
    collection.last_changed_at,
    collection.deleted_at,
    collection.last_synced_at,
    collection.pending_change,
    _keptOf(collection.pending_views, entries),
    pendingEntries);
}

/**
 * The same collection with one entry as the server now has it, and nothing left
 * owed about that entry.
 *
 * Where it sits in the list is where it already was: a collection has no order,
 * so there is nothing for the server to have moved.
 *
 * @param collection {Collection}
 * @param dto {import("./api.js").CollectionEntryDto}
 * @return {Collection}
 * @private
 */
function _withStoredEntry(collection, dto) {
  const stored = _entryOf(dto);

  // Its own view is the one this device has: the answer carries the view the
  // server knew about, which is older than one that is still waiting to be
  // sent.
  const here = collection.entries.find((entry) => entry.id === stored.id);
  if (here != null && collection.pending_views.includes(stored.id)) {
    stored.view = _viewOf(here.view);
  }

  const entries = here == null
    ? [...collection.entries, stored]
    : collection.entries.map((entry) => entry.id === stored.id ? stored : entry);

  return _withEntries(collection, entries, _withoutOwed(collection.pending_entries, stored.id));
}

/**
 * The same collection with nothing left owed about one entry.
 *
 * @param collection {Collection}
 * @param entryId {string}
 * @return {Collection}
 * @private
 */
function _withoutPendingEntry(collection, entryId) {
  return _withEntries(
    collection, collection.entries, _withoutOwed(collection.pending_entries, entryId));
}

/**
 * What is owed about the entries of a collection, with one entry now owing
 * this.
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
 * The same collection with one entry looked at differently, and that entry
 * marked as owed to the server or no longer owed.
 *
 * @param collection {Collection}
 * @param entryId {string}
 * @param view {EntryView}
 * @param owed {boolean}
 * @return {Collection}
 * @private
 */
function _withEntryView(collection, entryId, view, owed) {
  const pending = collection.pending_views.filter((id) => id !== entryId);
  if (owed) {
    pending.push(entryId);
  }

  return new Collection(
    collection.id,
    collection.title,
    collection.description,
    collection.entries.map((entry) => entry.id !== entryId ? entry : new CollectionEntry(
      entry.id,
      entry.score_id,
      entry.description,
      entry.transposition,
      view,
      entry.synced)),
    collection.shared_with,
    collection.is_owner,
    collection.last_changed_at,
    collection.deleted_at,
    collection.last_synced_at,
    collection.pending_change,
    pending,
    collection.pending_entries);
}

/**
 * The same collection with nothing left to say about one entry.
 *
 * @param collection {Collection}
 * @param entryId {string}
 * @return {Collection}
 * @private
 */
function _withoutPendingView(collection, entryId) {
  return new Collection(
    collection.id,
    collection.title,
    collection.description,
    collection.entries,
    collection.shared_with,
    collection.is_owner,
    collection.last_changed_at,
    collection.deleted_at,
    collection.last_synced_at,
    collection.pending_change,
    collection.pending_views.filter((id) => id !== entryId),
    collection.pending_entries);
}

/**
 * The entry ids of `owed` that the given entries still have. A view of an entry
 * that is no longer in the collection is about a piece that is no longer in it.
 *
 * @param owed {string[]|null|undefined}
 * @param entries {CollectionEntry[]}
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
 * The same collection, with nothing left owed to the server.
 *
 * @param collection {Collection}
 * @param syncedAt {Date|null}
 * @return {Collection}
 * @private
 */
function _synced(collection, syncedAt) {
  return new Collection(
    collection.id,
    collection.title,
    collection.description,
    collection.entries,
    collection.shared_with,
    collection.is_owner,
    collection.last_changed_at,
    collection.deleted_at,
    syncedAt,
    PendingChange.None,
    collection.pending_views,
    collection.pending_entries);
}

/**
 * A collection as the API reads it: what the group of pieces is, and who may
 * read it. What is in it is written an entry at a time and is not stated here.
 *
 * @param collection {Collection}
 * @return {WriteCollectionDto}
 * @private
 */
function _writeCollectionOf(collection) {
  return new WriteCollectionDto(
    collection.title, collection.description, [...collection.shared_with]);
}

/**
 * One entry, with everything the API insists on filled in: it asks for all of
 * them, and an entry that came from a form has only what was typed into it.
 *
 * @param entry {Object}
 * @return {CollectionEntry}
 * @private
 */
function _entryOf(entry) {
  return new CollectionEntry(
    // An entry that has not been named yet is named here rather than by the
    // server. It is what a view of it points at, and a player who puts a piece
    // in the book and says how they read it has to be able to say both before
    // either has been sent anywhere.
    entry.id ?? crypto.randomUUID(),
    _scoreIdOf(entry.score_id),
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
    Array.isArray(view?.hidden_parts) ? [...view.hidden_parts] : [],
    // A view that came from a server that has not been updated yet is a score
    // drawn the size it is written at.
    view?.zoom == null ? 1 : clampZoom(Number(view.zoom)));
}

/**
 * The score an entry is of, and null for a piece that has none.
 *
 * A blank is nothing rather than a score with no name: a form hands over what
 * was typed into it, and what nobody typed a score into is a piece that is in
 * the collection but not in here.
 *
 * @param scoreId {*}
 * @return {string|null}
 * @private
 */
function _scoreIdOf(scoreId) {
  return scoreId == null || `${scoreId}`.trim() === '' ? null : `${scoreId}`;
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
 * The addresses a collection is shared with, as the API compares them: in lower
 * case, each of them once. Whether they are addresses at all is the server's to
 * say — it refuses anything that is not one rather than tidying it up, and a
 * share that was going to go nowhere is better said so than quietly dropped
 * here.
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

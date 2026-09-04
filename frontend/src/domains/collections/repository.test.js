import test from 'node:test';
import assert from 'node:assert/strict';

import {CollectionsRepository, ScoreAlreadyInCollectionError} from './repository.js';
import {CollectionsApiError} from './api.js';
import {PendingChange} from './database.js';

// ----------------------------------------------------------------------------
// STAND-INS
// ----------------------------------------------------------------------------

/** The database, as far as the repository can tell: rows kept in a map. */
class FakeDatabase {
  rows = new Map();

  async fetchCollections() {
    return Array.from(this.rows.values());
  }

  async saveCollections(collections) {
    for (const collection of collections) {
      this.rows.set(collection.id, collection);
    }
  }

  async saveCollection(collection) {
    await this.saveCollections([collection]);
  }
}

class FakeOidc {
  constructor(api) {
    this._api = api;
  }

  async canBeReached() {
    return this._api.online;
  }

  async getActiveAccessToken() {
    return 'a-token';
  }
}

/**
 * The API, holding what the server is meant to know about.
 *
 * `online` is the network: with it off, every call fails the way a call with
 * nothing at the other end fails — a {@link CollectionsApiError} with no
 * status, since nothing answered and so nothing was said about the request.
 *
 * It holds the one rule a collection has that a set does not: a score is in a
 * collection once, and a second entry naming it is a conflict that says which
 * entry it is already in.
 */
class FakeApi {
  /** @param collections {object[]} */
  constructor(collections = []) {
    this.collections = new Map(collections.map((one) => [one.id, one]));
    this.online = true;
    this.puts = [];
    this.entryPuts = [];
    this.entryDeletes = [];
    this.viewPuts = [];
    /** How the one user this client calls as looks at each entry. */
    this.views = new Map();
    this.deletes = [];
    this.listedWindows = [];
    this.getCalls = [];
    /** @type {CollectionsApiError|null} thrown by the next view write, once */
    this.failViewWith = null;
    /** @type {CollectionsApiError|null} thrown by the next entry write, once */
    this.failEntryWith = null;
    /** @type {CollectionsApiError|null} thrown by the next put, once */
    this.failPutWith = null;
    /** @type {CollectionsApiError|null} thrown by every get */
    this.failGetWith = null;
  }

  async canBeReached() {
    return this.online;
  }

  _requireOnline(what) {
    if (!this.online) {
      throw new CollectionsApiError(`failed to ${what}: offline`, null);
    }
  }

  async listCollections(changesSince, changesUntil) {
    this._requireOnline('list the collections');
    this.listedWindows.push({since: changesSince, until: changesUntil});
    return Array.from(this.collections.values()).filter((collection) => {
      const changedAt = new Date(collection.last_changed_at);
      return (changesSince == null || changedAt >= changesSince)
        && (changesUntil == null || changedAt <= changesUntil);
    });
  }

  async getCollection(collectionId) {
    this._requireOnline('fetch the collection');
    this.getCalls.push(collectionId);
    if (this.failGetWith != null) {
      throw this.failGetWith;
    }
    const found = this.collections.get(collectionId);
    return found == null || found.deleted_at != null ? null : found;
  }

  async putCollection(collectionId, authToken, writeCollection) {
    this._requireOnline('save the collection');
    if (this.failPutWith != null) {
      const failure = this.failPutWith;
      this.failPutWith = null;
      throw failure;
    }

    this.puts.push({collectionId, writeCollection});
    // What is in a collection is not written with the collection: an entry is
    // its own resource, so one that is written keeps whatever it held.
    const stored = {
      ...(this.collections.get(collectionId) ?? {entries: []}),
      id: collectionId,
      title: writeCollection.title,
      description: writeCollection.description,
      shared_with: writeCollection.shared_with,
      is_owner: true,
      last_changed_at: new Date().toISOString(),
      deleted_at: null,
    };
    this.collections.set(collectionId, stored);
    return stored;
  }

  async putEntry(collectionId, entryId, authToken, writeEntry) {
    this._requireOnline('save the entry');
    if (this.failEntryWith != null) {
      const failure = this.failEntryWith;
      this.failEntryWith = null;
      throw failure;
    }

    const collection = this.collections.get(collectionId);
    if (collection == null) {
      throw new CollectionsApiError(
        'no such collection', 404, {errorCode: 'collection_not_found'});
    }

    const alreadyIn = writeEntry.score_id == null ? null : collection.entries.find(
      (entry) => entry.id !== entryId && entry.score_id === writeEntry.score_id);
    if (alreadyIn != null) {
      throw new CollectionsApiError('already in the collection', 409, {
        errorCode: 'score_already_in_collection',
        scoreId: writeEntry.score_id,
        entryId: alreadyIn.id,
      });
    }

    this.entryPuts.push({collectionId, entryId, writeEntry});

    const stored = {
      id: entryId,
      score_id: writeEntry.score_id,
      description: writeEntry.description,
      transposition: writeEntry.transposition,
      view: this.views.get(entryId) ?? {transposition: 0, hidden_parts: []},
    };

    const others = collection.entries.filter((entry) => entry.id !== entryId);
    collection.entries = [...others, stored];
    return stored;
  }

  async deleteEntry(collectionId, entryId) {
    this._requireOnline('delete the entry');
    if (this.failEntryWith != null) {
      const failure = this.failEntryWith;
      this.failEntryWith = null;
      throw failure;
    }

    this.entryDeletes.push({collectionId, entryId});
    const collection = this.collections.get(collectionId);
    if (collection == null) {
      return;
    }
    collection.entries = collection.entries.filter((entry) => entry.id !== entryId);
  }

  async putEntryView(collectionId, entryId, authToken, writeView) {
    this._requireOnline('save the view');
    if (this.failViewWith != null) {
      const failure = this.failViewWith;
      this.failViewWith = null;
      throw failure;
    }

    const collection = this.collections.get(collectionId);
    const entry = collection?.entries.find((candidate) => candidate.id === entryId);
    if (entry == null) {
      throw new CollectionsApiError(
        'no such entry', 404, {errorCode: 'collection_entry_not_found'});
    }

    const view = {
      transposition: writeView.transposition,
      hidden_parts: writeView.hidden_parts,
      zoom: writeView.zoom,
    };
    this.viewPuts.push({collectionId, entryId, view});
    this.views.set(entryId, view);
    entry.view = view;
    return view;
  }

  async deleteCollection(collectionId) {
    this._requireOnline('delete the collection');
    this.deletes.push(collectionId);
    const found = this.collections.get(collectionId);
    if (found != null) {
      this.collections.set(collectionId, {
        ...found,
        deleted_at: new Date().toISOString(),
        last_changed_at: new Date().toISOString(),
      });
    }
  }
}

/** A score for a collection to point at. */
const A_SCORE = '2b0f0b4e-0d1a-4c9a-9a5f-2c8f7a1b3d4e';
/** Another one, for the tests about holding a piece once. */
const ANOTHER_SCORE = '9f3d1c22-6a44-4f0b-8c31-7d2e5b6a1c90';

/**
 * A collection as the API hands it over.
 *
 * @param id {string}
 * @param overrides {object}
 */
function aCollection(id, overrides = {}) {
  return {
    id,
    title: 'The Real Book, vol. 1',
    description: 'what we can be asked for',
    entries: [{
      id: `${id}-entry-0`,
      score_id: A_SCORE,
      description: 'page 62',
      transposition: -2,
      view: {transposition: 0, hidden_parts: []},
    }],
    shared_with: [],
    is_owner: true,
    last_changed_at: '2026-08-01T12:00:00.000Z',
    deleted_at: null,
    ...overrides,
  };
}

/**
 * A collection as a form hands it over: what was typed, and nothing else.
 *
 * @param overrides {object}
 */
function aDraft(overrides = {}) {
  return {
    title: 'The Real Book, vol. 1',
    description: '',
    shared_with: [],
    ...overrides,
  };
}

/**
 * A collection with one piece in it, which is what most of these tests want to
 * start from: a collection is created empty and filled afterwards.
 *
 * @param repository {CollectionsRepository}
 * @param overrides {object}
 */
async function aCollectionWithOnePiece(repository, overrides = {}) {
  const collection = await repository.saveCollection(aDraft(overrides));
  return await repository.saveEntry(collection.id, {score_id: A_SCORE});
}

/**
 * A repository with nothing stored locally and the given collections on the
 * server.
 *
 * @param collections {object[]}
 */
function aRepository(collections = []) {
  const database = new FakeDatabase();
  const api = new FakeApi(collections);
  const repository = new CollectionsRepository(database, api, new FakeOidc(api));
  return {repository, database, api};
}

/** @param status {number} @param errorCode {string|null} */
function refusal(status, errorCode = null) {
  return new CollectionsApiError('refused', status, errorCode == null ? null : {errorCode});
}

// ----------------------------------------------------------------------------
// WHAT A COLLECTION IS
// ----------------------------------------------------------------------------

test('a collection that could be sent is stored the way the server made of it', async () => {
  const {repository, api} = aRepository();
  await repository.init();

  const saved = await repository.saveCollection(aDraft());

  assert.equal(api.puts.length, 1, 'the collection should have been sent right away');
  assert.equal(saved.pending_change, PendingChange.None, 'nothing should still be owed');
  assert.deepEqual(saved.entries, [], 'a collection is created empty and filled afterwards');
  assert.ok(saved.last_synced_at instanceof Date);
});

// What is in a collection is written a piece at a time, so a collection that is
// written says nothing about it: correcting a title must not empty the book.
test('writing a collection leaves what is in it alone', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await aCollectionWithOnePiece(repository);

  const saved = await repository.saveCollection({id: created.id, title: 'Corrected'});

  assert.equal(saved.title, 'Corrected');
  assert.equal(saved.entries.length, 1, 'correcting the title emptied the collection');
  assert.equal(api.collections.get(created.id).entries.length, 1);
});

test('a collection that is deleted is kept as a headstone', async () => {
  const {repository, api, database} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  await repository.deleteCollection(created.id);

  assert.deepEqual(api.deletes, [created.id]);
  assert.equal(repository.getCollection(created.id), null, 'it should be gone');
  assert.ok(database.rows.get(created.id).deleted_at != null,
    'a collection that was simply forgotten would be synced straight back in');
});

// ----------------------------------------------------------------------------
// A COLLECTION HOLDS A PIECE ONCE
// ----------------------------------------------------------------------------

test('a score that is already in the collection is not put in twice', async () => {
  const {repository} = aRepository();
  await repository.init();
  const created = await aCollectionWithOnePiece(repository);
  const alreadyIn = created.entries[0];

  await assert.rejects(
    () => repository.saveEntry(created.id, {score_id: A_SCORE}),
    (error) => {
      assert.ok(error instanceof ScoreAlreadyInCollectionError);
      assert.equal(error.scoreId, A_SCORE);
      assert.equal(error.entryId, alreadyIn.id,
        'the refusal should name the entry the piece is already in');
      return true;
    });

  assert.equal(repository.getCollection(created.id).entries.length, 1);
});

// Writing the entry a score is already in is not putting the piece in twice: it
// is saying what the group does with a piece the collection already holds,
// which is the whole point of an entry.
test('the entry a score is in can be written without being refused', async () => {
  const {repository} = aRepository();
  await repository.init();
  const created = await aCollectionWithOnePiece(repository);
  const entry = created.entries[0];

  const saved = await repository.saveEntry(created.id, {id: entry.id, transposition: -2});

  assert.equal(saved.entries.length, 1);
  assert.equal(saved.entries[0].transposition, -2);
});

// They have no score to be the same score, and they are told apart by what is
// written next to them: two lines of a book nobody has scanned are two pieces.
test('two pieces that have no score are two pieces', async () => {
  const {repository} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  await repository.saveEntry(created.id, {score_id: null, description: 'page 12'});
  const saved = await repository.saveEntry(created.id, {score_id: null, description: 'page 44'});

  assert.equal(saved.entries.length, 2);
  assert.deepEqual(saved.entries.map((entry) => entry.description), ['page 12', 'page 44']);
});

test('a piece that is taken out can be put back in', async () => {
  const {repository} = aRepository();
  await repository.init();
  const created = await aCollectionWithOnePiece(repository);

  const emptied = await repository.deleteEntry(created.id, created.entries[0].id);
  assert.equal(emptied.entries.length, 0);

  const filled = await repository.saveEntry(created.id, {score_id: A_SCORE});
  assert.equal(filled.entries.length, 1, 'the rule should be about what is in it now');
});

test('the collections a score is in are the ones that hold it', async () => {
  const {repository} = aRepository();
  await repository.init();
  const holding = await aCollectionWithOnePiece(repository);
  const other = await repository.saveCollection(aDraft({title: 'Another book'}));
  await repository.saveEntry(other.id, {score_id: ANOTHER_SCORE});

  const found = repository.collectionsWith(A_SCORE);

  assert.deepEqual(found.map((collection) => collection.id), [holding.id]);
});

// ----------------------------------------------------------------------------
// WRITING WITH NO NETWORK
// ----------------------------------------------------------------------------

test('a piece added with no network is kept and sent at the next sync', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  api.online = false;
  const written = await repository.saveEntry(created.id, {score_id: A_SCORE});

  assert.equal(written.entries.length, 1, 'it should be in the collection on this device');
  assert.equal(written.pending_entries.length, 1, 'and still owed to the server');
  assert.equal(api.entryPuts.length, 0);

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.entryPuts.length, 1, 'the piece should have gone out at the sync');
  assert.equal(repository.getCollection(created.id).pending_entries.length, 0);
});

// A collection that still owes the server a write was written after the last
// thing the server said, so it is the newer of the two.
test('what was written here wins until it has been pushed', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  api.online = false;
  await repository.saveCollection({id: created.id, title: 'Written here'});
  api.online = true;

  // The server's copy is older, and a pull must not undo the edit.
  api.collections.get(created.id).title = 'What the server had';
  await repository._pull();

  assert.equal(repository.getCollection(created.id).title, 'Written here');
});

test('a piece the server never heard of is nothing to tell it about', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  api.online = false;
  const written = await repository.saveEntry(created.id, {score_id: A_SCORE});
  await repository.deleteEntry(created.id, written.entries[0].id);
  api.online = true;
  await repository.syncWithApi();

  assert.deepEqual(api.entryDeletes, [], 'there was no row there to remove');
  assert.deepEqual(api.entryPuts, [], 'and nothing to write either');
});

// ----------------------------------------------------------------------------
// HOW ONE PLAYER READS A PIECE
// ----------------------------------------------------------------------------

test('a view is written by whoever it belongs to, owner or not', async () => {
  const shared = aCollection('c-1', {is_owner: false});
  const {repository, api} = aRepository([shared]);
  await repository.init();
  await repository.syncWithApi();

  const saved = await repository.saveEntryView('c-1', 'c-1-entry-0', {
    transposition: 5,
    hidden_parts: ['P2'],
    zoom: 1.5,
  });

  assert.equal(api.viewPuts.length, 1, 'reading a collection is enough to say how you read it');
  assert.equal(saved.entries[0].view.transposition, 5);
  assert.deepEqual(saved.entries[0].view.hidden_parts, ['P2']);
  assert.equal(saved.entries[0].view.zoom, 1.5);
  assert.deepEqual(repository.getCollection('c-1').pending_views, []);
});

test('a view waits for the piece it is about', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  api.online = false;
  const written = await repository.saveEntry(created.id, {score_id: A_SCORE});
  const entryId = written.entries[0].id;
  await repository.saveEntryView(created.id, entryId, {transposition: 3, hidden_parts: []});
  api.online = true;

  api.failEntryWith = refusal(503);
  await repository.syncWithApi();

  assert.equal(api.viewPuts.length, 0,
    'the server has nothing to hang a view on while the piece is still queued');
  assert.equal(repository.getCollection(created.id).pending_views.length, 1);

  await repository.syncWithApi();
  assert.equal(api.viewPuts.length, 1, 'the view should follow the piece out');
});

// ----------------------------------------------------------------------------
// WHEN THE SERVER SAYS NO
// ----------------------------------------------------------------------------

test('an edit the server will refuse again is taken back and reported', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());
  api.collections.get(created.id).title = 'What the server has';

  const problems = [];
  repository.addSyncProblemListener((problem) => problems.push(problem));

  api.online = false;
  await repository.saveCollection({id: created.id, title: 'Refused'});
  api.online = true;
  api.failPutWith = refusal(400, 'invalid_collection');
  await repository.syncWithApi();

  assert.equal(problems.length, 1, 'an edit dropped quietly is worse than one dropped loudly');
  assert.equal(repository.getCollection(created.id).title, 'What the server has');
  assert.equal(repository.getCollection(created.id).pending_change, PendingChange.None);
});

test('an edit that failed for a reason that may pass stays queued', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  const problems = [];
  repository.addSyncProblemListener((problem) => problems.push(problem));

  api.online = false;
  await repository.saveCollection({id: created.id, title: 'Written here'});
  api.online = true;
  api.failPutWith = refusal(401);
  await repository.syncWithApi();

  assert.deepEqual(problems, [], 'a token that ran out says nothing about what was written');
  assert.equal(repository.getCollection(created.id).title, 'Written here');

  await repository.syncWithApi();
  assert.equal(repository.getCollection(created.id).pending_change, PendingChange.None);
});

// Two devices, one book: somebody else put the piece in while this one was
// offline. The piece is in the collection, which is what was wanted, so this
// second copy of it goes rather than being asked for over and over.
test('a piece the server already holds is dropped rather than kept queued', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await repository.saveCollection(aDraft());

  api.online = false;
  const written = await repository.saveEntry(created.id, {score_id: A_SCORE});
  const mine = written.entries[0].id;
  api.online = true;

  // Somebody else got there first, under an entry of their own.
  api.collections.get(created.id).entries.push({
    id: 'somebody-elses-entry',
    score_id: A_SCORE,
    description: '',
    transposition: 0,
    view: {transposition: 0, hidden_parts: []},
  });

  await repository.syncWithApi();

  const collection = repository.getCollection(created.id);
  assert.deepEqual(collection.pending_entries, [], 'it should not keep being asked for');
  assert.deepEqual(
    collection.entries.filter((entry) => entry.id === mine), [],
    'the second copy of the piece should be gone');
  assert.equal(
    collection.entries.filter((entry) => entry.score_id === A_SCORE).length, 1,
    'and the piece should be in the collection exactly once');
});

// ----------------------------------------------------------------------------
// READING WHAT THE SERVER HAS
// ----------------------------------------------------------------------------

test('a sync asks about everything the first time and about the window after', async () => {
  const {repository, api} = aRepository([aCollection('c-1')]);
  await repository.init();

  await repository.syncWithApi();
  assert.equal(api.listedWindows[0].since, null, 'the first sync asks about everything there is');

  await repository.syncWithApi();
  assert.ok(api.listedWindows[1].since instanceof Date,
    'a later sync asks about what changed since the last one');
});

test('a collection that was deleted on the server is kept as a headstone here', async () => {
  const {repository, api, database} = aRepository([aCollection('c-1')]);
  await repository.init();
  await repository.syncWithApi();

  api.collections.set('c-1', {
    ...api.collections.get('c-1'),
    deleted_at: new Date().toISOString(),
    last_changed_at: new Date().toISOString(),
  });
  await repository.syncWithApi();

  assert.equal(repository.getCollection('c-1'), null);
  assert.ok(database.rows.get('c-1').deleted_at != null);
});

test('a collection that is only shared with this user is not this user\'s to change', async () => {
  const {repository} = aRepository([aCollection('c-1', {is_owner: false})]);
  await repository.init();
  await repository.syncWithApi();

  await assert.rejects(() => repository.saveCollection({id: 'c-1', title: 'Mine now'}));
  await assert.rejects(() => repository.saveEntry('c-1', {score_id: ANOTHER_SCORE}));
  await assert.rejects(() => repository.deleteCollection('c-1'));
});

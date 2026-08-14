import test from 'node:test';
import assert from 'node:assert/strict';

import {SetsRepository} from './repository.js';
import {SetsApiError} from './api.js';
import {PendingChange} from './database.js';

// ----------------------------------------------------------------------------
// STAND-INS
// ----------------------------------------------------------------------------

/** The database, as far as the repository can tell: rows kept in a map. */
class FakeDatabase {
  rows = new Map();

  async fetchSets() {
    return Array.from(this.rows.values());
  }

  async saveSets(sets) {
    for (const set of sets) {
      this.rows.set(set.id, set);
    }
  }

  async saveSet(set) {
    await this.saveSets([set]);
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
 * nothing at the other end fails — a {@link SetsApiError} with no status, since
 * nothing answered and so nothing was said about the request.
 */
class FakeApi {
  /** @param sets {object[]} */
  constructor(sets = []) {
    this.sets = new Map(sets.map((set) => [set.id, set]));
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
    /** @type {SetsApiError|null} thrown by the next view write, once */
    this.failViewWith = null;
    /** @type {SetsApiError|null} thrown by the next entry write, once */
    this.failEntryWith = null;
    /** @type {SetsApiError|null} thrown by the next put, once */
    this.failPutWith = null;
    /** @type {SetsApiError|null} thrown by the next delete, once */
    this.failDeleteWith = null;
    /** @type {SetsApiError|null} thrown by every get */
    this.failGetWith = null;
  }

  async canBeReached() {
    return this.online;
  }

  _requireOnline(what) {
    if (!this.online) {
      throw new SetsApiError(`failed to ${what}: offline`, null);
    }
  }

  async listSets(changesSince, changesUntil) {
    this._requireOnline('list the sets');
    this.listedWindows.push({since: changesSince, until: changesUntil});
    return Array.from(this.sets.values()).filter((set) => {
      const changedAt = new Date(set.last_changed_at);
      return (changesSince == null || changedAt >= changesSince)
        && (changesUntil == null || changedAt <= changesUntil);
    });
  }

  async getSet(setId) {
    this._requireOnline('fetch the set');
    this.getCalls.push(setId);
    if (this.failGetWith != null) {
      throw this.failGetWith;
    }
    const found = this.sets.get(setId);
    return found == null || found.deleted_at != null ? null : found;
  }

  async putSet(setId, authToken, writeSet) {
    this._requireOnline('save the set');
    if (this.failPutWith != null) {
      const failure = this.failPutWith;
      this.failPutWith = null;
      throw failure;
    }

    this.puts.push({setId, writeSet});
    // What is played in a set is not written with the set: an entry is its own
    // resource, so a set that is written keeps whatever entries it had.
    const stored = {
      ...(this.sets.get(setId) ?? {entries: []}),
      id: setId,
      title: writeSet.title,
      description: writeSet.description,
      shared_with: writeSet.shared_with,
      is_owner: true,
      last_changed_at: new Date().toISOString(),
      deleted_at: null,
    };
    this.sets.set(setId, stored);
    return stored;
  }

  async putEntry(setId, entryId, authToken, writeEntry) {
    this._requireOnline('save the entry');
    if (this.failEntryWith != null) {
      const failure = this.failEntryWith;
      this.failEntryWith = null;
      throw failure;
    }

    const set = this.sets.get(setId);
    if (set == null) {
      throw new SetsApiError('no such set', 404, {errorCode: 'set_not_found'});
    }

    this.entryPuts.push({setId, entryId, writeEntry});

    const others = set.entries.filter((entry) => entry.id !== entryId);
    const position = Math.min(Math.max(writeEntry.position, 0), others.length);
    const stored = {
      id: entryId,
      score_id: writeEntry.score_id,
      description: writeEntry.description,
      transposition: writeEntry.transposition,
      position: position,
      view: this.views.get(entryId) ?? {transposition: 0, hidden_parts: []},
    };

    // The set is closed up around it, and the places are nought upwards.
    set.entries = [...others.slice(0, position), stored, ...others.slice(position)]
      .map((entry, at) => ({...entry, position: at}));
    return set.entries[position];
  }

  async deleteEntry(setId, entryId, authToken) {
    this._requireOnline('delete the entry');
    if (this.failEntryWith != null) {
      const failure = this.failEntryWith;
      this.failEntryWith = null;
      throw failure;
    }

    this.entryDeletes.push({setId, entryId});
    const set = this.sets.get(setId);
    if (set == null) {
      return;
    }
    set.entries = set.entries
      .filter((entry) => entry.id !== entryId)
      .map((entry, at) => ({...entry, position: at}));
  }

  async putEntryView(setId, entryId, authToken, writeView) {
    this._requireOnline('save the view');
    if (this.failViewWith != null) {
      const failure = this.failViewWith;
      this.failViewWith = null;
      throw failure;
    }

    const set = this.sets.get(setId);
    const entry = set?.entries.find((candidate) => candidate.id === entryId);
    if (entry == null) {
      throw new SetsApiError('no such entry', 404, {errorCode: 'set_entry_not_found'});
    }

    const view = {
      transposition: writeView.transposition,
      hidden_parts: writeView.hidden_parts,
      zoom: writeView.zoom,
    };
    this.viewPuts.push({setId, entryId, view});
    this.views.set(entryId, view);
    entry.view = view;
    return view;
  }

  async deleteSet(setId) {
    this._requireOnline('delete the set');
    if (this.failDeleteWith != null) {
      const failure = this.failDeleteWith;
      this.failDeleteWith = null;
      throw failure;
    }

    this.deletes.push(setId);
    const found = this.sets.get(setId);
    if (found != null) {
      this.sets.set(setId, {
        ...found,
        deleted_at: new Date().toISOString(),
        last_changed_at: new Date().toISOString(),
      });
    }
  }
}

/**
 * A set as the API hands it over.
 *
 * @param id {string}
 * @param overrides {object}
 */
function aSet(id, overrides = {}) {
  return {
    id,
    title: 'Zomerbar 12 juli',
    description: 'two sets of forty minutes',
    entries: [{
      id: `${id}-entry-0`,
      score_id: '2b0f0b4e-0d1a-4c9a-9a5f-2c8f7a1b3d4e',
      description: 'capo 2',
      transposition: -2,
      position: 0,
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
 * A set as a form hands it over: what was typed, and nothing else.
 *
 * @param overrides {object}
 */
function aDraft(overrides = {}) {
  return {
    title: 'Zomerbar 12 juli',
    description: '',
    shared_with: [],
    ...overrides,
  };
}

/** A score for a set to point at. */
const A_SCORE = '2b0f0b4e-0d1a-4c9a-9a5f-2c8f7a1b3d4e';

/**
 * A set with one song in it, which is what most of these tests want to start
 * from: a set is created empty and filled afterwards.
 *
 * @param repository {SetsRepository}
 * @param overrides {object}
 */
async function aSetWithOneSong(repository, overrides = {}) {
  const set = await repository.saveSet(aDraft(overrides));
  return await repository.saveEntry(set.id, {score_id: A_SCORE});
}

/**
 * A repository with nothing stored locally and the given sets on the server.
 *
 * @param sets {object[]}
 */
function aRepository(sets = []) {
  const database = new FakeDatabase();
  const api = new FakeApi(sets);
  const repository = new SetsRepository(database, api, new FakeOidc(api));
  return {repository, database, api};
}

/** @param status {number} @param errorCode {string|null} */
function refusal(status, errorCode = null) {
  return new SetsApiError('refused', status, errorCode == null ? null : {errorCode});
}

// ----------------------------------------------------------------------------
// WRITING WHILE THERE IS A NETWORK
// ----------------------------------------------------------------------------

test('a set that could be sent is stored the way the server made of it', async () => {
  const {repository, api} = aRepository();
  await repository.init();

  const saved = await repository.saveSet(aDraft());

  assert.equal(api.puts.length, 1, 'the set should have been sent right away');
  assert.equal(saved.pending_change, PendingChange.None, 'nothing should still be owed');
  assert.deepEqual(saved.entries, [], 'a set is created empty and filled afterwards');
  assert.ok(saved.last_synced_at instanceof Date);
});

// What is played in a set is written a song at a time, so a set that is written
// says nothing about it. Before entries were their own resource this was a real
// hazard: correcting a title restated the whole running order.
test('writing a set leaves what is played in it alone', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  const created = await aSetWithOneSong(repository);

  const saved = await repository.saveSet({id: created.id, title: 'Corrected'});

  assert.equal(saved.title, 'Corrected');
  assert.equal(saved.entries.length, 1, 'correcting the title emptied the set');
  assert.equal(api.sets.get(created.id).entries.length, 1);
  assert.equal(api.puts.at(-1).writeSet.entries, undefined,
    'a set should be stated as what it is, not as what is played in it');
});

// An entry carries what every player has said about how they look at it, and
// all of that hangs off its id. An entry that came back with one and is written
// again without it would be a new entry, and every reading of it would be gone.
test('an entry is sent under the id it is known by here', async () => {
  const {repository, api} = aRepository();
  await repository.init();

  const saved = await aSetWithOneSong(repository);

  assert.equal(api.entryPuts.length, 1);
  assert.equal(api.entryPuts[0].entryId, saved.entries[0].id,
    'an entry was sent without saying which entry it is');
  assert.deepEqual(Object.keys(api.entryPuts[0].writeEntry).sort(),
    ['description', 'position', 'score_id', 'transposition']);
});

// A gig is where a song gets added to the set, and where the player who added
// it says how they read it — both before either has been anywhere near a
// server. Naming the entry here is what lets the second of those point at the
// first.
test('an entry that has not been sent anywhere is still named', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;

  const saved = await aSetWithOneSong(repository);

  assert.ok(saved.entries[0].id, 'an entry with no id is an entry no view can point at');
});

test('what a form left out is filled in with what the API insists on', async () => {
  const {repository, api} = aRepository();
  await repository.init();

  const set = await repository.saveSet(aDraft());
  const saved = await repository.saveEntry(set.id, {score_id: 'a-score'});

  assert.deepEqual({...api.entryPuts[0].writeEntry}, {
    score_id: 'a-score',
    description: '',
    transposition: 0,
    position: 0,
  });
  assert.deepEqual({...saved.entries[0].view}, {transposition: 0, hidden_parts: [], zoom: 1},
    'an entry nobody has looked at differently is as written, every part on screen, '
    + 'at the size it is written at');
});

test('a transposition further than the player offers is brought back to it', async () => {
  const {repository, api} = aRepository();
  await repository.init();

  const set = await repository.saveSet(aDraft());
  for (const transposition of [99, -99, 1.6, 'not a number']) {
    await repository.saveEntry(set.id, {score_id: 'a-score', transposition});
  }

  assert.deepEqual(api.entryPuts.map((put) => put.writeEntry.transposition),
    [12, -12, 2, 0]);
});

test('an address is shared with once, whatever case it was typed in', async () => {
  const {repository, api} = aRepository();
  await repository.init();

  await repository.saveSet(aDraft({shared_with: ['Bas@Example.com', ' bas@example.com ', '']}));

  assert.deepEqual(api.puts[0].writeSet.shared_with, ['bas@example.com']);
});

// ----------------------------------------------------------------------------
// WRITING WHILE THERE IS NONE
// ----------------------------------------------------------------------------

// This is the whole point of keeping sets here: a set is a playlist for a gig,
// and a gig is exactly where there is no network to write one over.
test('a set written with nothing at the other end is kept and sent at the next sync', async () => {
  const {repository, database, api} = aRepository();
  await repository.init();
  api.online = false;

  const saved = await repository.saveSet(aDraft({title: 'Zomerbar 12 juli'}));

  assert.equal(saved.pending_change, PendingChange.Write, 'the write should be owed to the server');
  assert.equal(repository.hasPendingChanges, true);
  assert.equal(repository.sets.length, 1, 'the set should be there to play from straight away');
  assert.equal(database.rows.get(saved.id).title, 'Zomerbar 12 juli',
    'it should have reached the database, not just the copy in memory');
  assert.equal(api.puts.length, 0, 'nothing can have been sent');

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.puts.length, 1, 'the queued write should have gone out');
  assert.equal(repository.getSet(saved.id).pending_change, PendingChange.None);
  assert.equal(repository.hasPendingChanges, false);
});

test('a set is written to over and over while offline and sent once', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;

  const first = await repository.saveSet(aDraft({title: 'first'}));
  await repository.saveSet(aDraft({id: first.id, title: 'second'}));
  await repository.saveSet(aDraft({id: first.id, title: 'third'}));

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.puts.length, 1, 'what is owed is the set as it now reads, not every edit made to it');
  assert.equal(api.puts[0].writeSet.title, 'third');
});

// A set with an edit still owed was written here after the last thing the
// server said, so it is the newer of the two whatever the server answers with.
test('a set that is still owed to the server is not overwritten by what a sync brings in', async () => {
  const setId = '6f5a1f0e-1c2b-4d3e-8f90-1a2b3c4d5e6f';
  const {repository, api} = aRepository([aSet(setId, {title: 'as the server has it'})]);
  await repository.init();
  await repository.syncWithApi();
  assert.equal(repository.getSet(setId).title, 'as the server has it');

  api.online = false;
  await repository.saveSet(aDraft({id: setId, title: 'as it was written here'}));

  // The network is back, but the write still cannot get through.
  api.online = true;
  api.failPutWith = refusal(503);
  await repository.syncWithApi();

  assert.equal(repository.getSet(setId).title, 'as it was written here',
    'a sync read the set back over an edit that had not been sent yet');
  assert.equal(repository.getSet(setId).pending_change, PendingChange.Write);
});

test('a write that failed for a reason that may pass is sent again at the next sync', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;
  const saved = await repository.saveSet(aDraft());

  api.online = true;
  api.failPutWith = refusal(500);
  await repository.syncWithApi();
  assert.equal(repository.getSet(saved.id).pending_change, PendingChange.Write,
    'a server that is unwell says nothing about the set that was written');

  await repository.syncWithApi();
  assert.equal(repository.getSet(saved.id).pending_change, PendingChange.None);
  assert.equal(api.puts.length, 1);
});

// A token that ran out mid-sync is about the caller, not about what was
// written: the same set is perfectly writable once there is a token again.
test('a write refused for want of a token is kept', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;
  const saved = await repository.saveSet(aDraft());

  api.online = true;
  api.failPutWith = refusal(401, 'invalid_credentials');
  await repository.syncWithApi();

  assert.equal(repository.getSet(saved.id).pending_change, PendingChange.Write);
});

// ----------------------------------------------------------------------------
// WRITES THE SERVER WILL NOT HAVE
// ----------------------------------------------------------------------------

// A set naming a score that does not exist is refused just as firmly the next
// time: keeping it queued would mean retrying it at every sync for good, and
// dropping it without saying so would lose an edit the player thinks they made.
test('a write the server will never take is given up on and reported', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;
  const saved = await repository.saveSet(aDraft({title: 'names a score that is not there'}));

  /** @type {object[]} */
  const problems = [];
  repository.addSyncProblemListener((problem) => problems.push(problem));

  api.online = true;
  api.failPutWith = refusal(400, 'unknown_score');
  await repository.syncWithApi();

  assert.equal(repository.getSet(saved.id), null,
    'a set the server has never heard of and will not take is not a set');
  assert.equal(repository.hasPendingChanges, false, 'it should not be retried at every sync for good');
  assert.equal(problems.length, 1, 'giving up on an edit has to be said out loud');
  assert.equal(problems[0].setId, saved.id);
  assert.equal(problems[0].action, PendingChange.Write);
  assert.equal(problems[0].error.errorCode, 'unknown_score');
});

test('an edit to a set that is not ours is taken back to the way the server has it', async () => {
  const setId = '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d';
  const {repository, api} = aRepository([aSet(setId, {title: 'as the server has it'})]);
  await repository.init();
  await repository.syncWithApi();

  // The set turns out to be someone else's, which this device only finds out by
  // trying: it thought it was the owner when the edit was made.
  api.online = false;
  await repository.saveSet(aDraft({id: setId, title: 'as it was written here'}));
  api.online = true;
  api.failPutWith = refusal(403, 'not_set_owner');

  await repository.syncWithApi();

  assert.equal(repository.getSet(setId).title, 'as the server has it');
  assert.equal(repository.getSet(setId).pending_change, PendingChange.None);
});

// The set is no longer owed to anybody, so what is left here is out of date
// rather than lost, and the player has been told.
test('an edit given up on when the set cannot be read back is left alone rather than queued', async () => {
  const setId = '3c2b1a09-8f7e-4d6c-9b5a-4f3e2d1c0b9a';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  await repository.saveSet(aDraft({id: setId, title: 'as it was written here'}));
  api.online = true;
  api.failPutWith = refusal(400, 'invalid_set');
  api.failGetWith = refusal(500);

  const problems = [];
  repository.addSyncProblemListener((problem) => problems.push(problem));
  await repository.syncWithApi();

  assert.equal(repository.getSet(setId).pending_change, PendingChange.None);
  assert.equal(problems.length, 1);
});

// ----------------------------------------------------------------------------
// DELETING
// ----------------------------------------------------------------------------

test('a set deleted with nothing at the other end is gone here and the delete is queued', async () => {
  const setId = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  await repository.deleteSet(setId);

  assert.equal(repository.getSet(setId), null, 'the set should be gone here straight away');
  assert.equal(repository.sets.length, 0);

  api.online = true;
  await repository.syncWithApi();

  assert.deepEqual(api.deletes, [setId]);
  assert.equal(repository.getSet(setId), null, 'a set that was deleted should stay deleted');
});

// A set the server never had is a set there is no row to mark as gone.
test('a set created and deleted before it ever reached the server is not sent at all', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;

  const saved = await repository.saveSet(aDraft());
  await repository.deleteSet(saved.id);

  api.online = true;
  await repository.syncWithApi();

  assert.deepEqual(api.puts, [], 'a set that no longer exists should not be created first');
  assert.deepEqual(api.deletes, []);
  assert.equal(repository.getSet(saved.id), null);
});

test('a set deleted on the server is not synced back in', async () => {
  const setId = 'd4c3b2a1-f6e5-4b7a-9c8d-1e0f2a3b4c5d';
  const {repository, database, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  assert.equal(repository.sets.length, 1);

  // Deleting it there is a change like any other, and it falls inside the
  // window the next sync asks about.
  const deletedAt = new Date().toISOString();
  api.sets.set(setId, {
    ...api.sets.get(setId),
    deleted_at: deletedAt,
    last_changed_at: deletedAt,
  });
  await repository.syncWithApi();

  assert.equal(repository.sets.length, 0, 'a set that was deleted elsewhere is gone here too');
  // A headstone rather than a removal: a sync only asks about what changed
  // since the last one, so a set that was simply forgotten here would come
  // straight back in as something new the next time the window covered it.
  assert.ok(database.rows.get(setId).deleted_at instanceof Date,
    'the set should be kept as deleted rather than dropped');
});

// ----------------------------------------------------------------------------
// WHAT IS PLAYED IN IT
// ----------------------------------------------------------------------------

test('a song put into a set at a gig is kept and sent at the next sync', async () => {
  const setId = 'c3d4e5f6-a7b8-4901-8c2d-3e4f5a6b7c8d';
  const {repository, database, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  const saved = await repository.saveEntry(setId, {score_id: A_SCORE, description: 'capo 2'});

  assert.equal(saved.entries.length, 1, 'the song should be in the set to play from straight away');
  assert.equal(saved.pending_entries.length, 1);
  assert.equal(repository.hasPendingChanges, true);
  assert.equal(database.rows.get(setId).entries[0].description, 'capo 2',
    'it should have reached the database, not just the copy in memory');

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.entryPuts.length, 1);
  assert.deepEqual(repository.getSet(setId).pending_entries, []);
});

test('a song is put in at the place it is given, and at the end when it is not', async () => {
  const setId = 'd4e5f6a7-b8c9-4012-8d3e-4f5a6b7c8d9e';
  const {repository, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();

  await repository.saveEntry(setId, {id: 'first', score_id: 'a'});
  await repository.saveEntry(setId, {id: 'last', score_id: 'b'});
  const saved = await repository.saveEntry(setId, {id: 'squeezed', score_id: 'c', position: 1});

  assert.deepEqual(saved.entries.map((entry) => entry.id), ['first', 'squeezed', 'last']);
  assert.equal(api.entryPuts.at(-1).writeEntry.position, 1);
});

test('a song that is written without being moved stays where it is', async () => {
  const setId = 'a1b2c3d4-e5f6-4789-8a1b-2c3d4e5f6a7c';
  const {repository, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();
  await repository.saveEntry(setId, {id: 'first', score_id: 'a'});
  await repository.saveEntry(setId, {id: 'second', score_id: 'b'});
  await repository.saveEntry(setId, {id: 'third', score_id: 'c'});

  const saved = await repository.saveEntry(setId, {id: 'first', description: 'capo 2'});

  assert.deepEqual(saved.entries.map((entry) => entry.id), ['first', 'second', 'third'],
    'saying what a song is called should not rearrange the gig');
  assert.equal(saved.entries[0].description, 'capo 2');
  assert.equal(api.entryPuts.at(-1).writeEntry.position, 0);
});

test('a song that moves is sent as the one song that moved', async () => {
  const setId = 'e5f6a7b8-c9d0-4123-8e4f-5a6b7c8d9e0f';
  const {repository, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();
  await repository.saveEntry(setId, {id: 'first', score_id: 'a'});
  await repository.saveEntry(setId, {id: 'second', score_id: 'b'});

  const saved = await repository.saveEntry(setId, {id: 'second', position: 0});

  assert.deepEqual(saved.entries.map((entry) => entry.id), ['second', 'first']);
  assert.equal(api.entryPuts.at(-1).entryId, 'second');
  assert.equal(api.entryPuts.at(-1).writeEntry.position, 0);
  assert.equal(api.entryPuts.at(-1).writeEntry.score_id, 'b',
    'moving a song should not have changed which song it is');
});

test('a song taken out of a set is taken out on the server too', async () => {
  const setId = 'f6a7b8c9-d0e1-4234-8f5a-6b7c8d9e0f1a';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  api.online = false;
  const saved = await repository.deleteEntry(setId, entryId);
  assert.deepEqual(saved.entries, [], 'the song should be out of the set straight away');

  api.online = true;
  await repository.syncWithApi();

  assert.deepEqual(api.entryDeletes.map((call) => call.entryId), [entryId]);
  assert.deepEqual(repository.getSet(setId).entries, []);
});

// There is no row on the server to remove, and nothing it could be told that it
// does not already believe.
test('a song put in and taken out again before either was sent is not sent at all', async () => {
  const setId = 'a7b8c9d0-e1f2-4345-8a6b-7c8d9e0f1a2b';
  const {repository, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  const added = await repository.saveEntry(setId, {score_id: A_SCORE});
  await repository.deleteEntry(setId, added.entries[0].id);

  api.online = true;
  await repository.syncWithApi();

  assert.deepEqual(api.entryPuts, []);
  assert.deepEqual(api.entryDeletes, []);
  assert.equal(repository.hasPendingChanges, false);
});

test('a song written over and over while offline is sent once, as it now reads', async () => {
  const setId = 'b8c9d0e1-f2a3-4456-8b7c-8d9e0f1a2b3c';
  const {repository, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  const added = await repository.saveEntry(setId, {score_id: A_SCORE, description: 'first'});
  const entryId = added.entries[0].id;
  await repository.saveEntry(setId, {id: entryId, description: 'second'});
  await repository.saveEntry(setId, {id: entryId, description: 'third'});

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.entryPuts.length, 1,
    'what is owed is the song as it now reads, not every edit made to it');
  assert.equal(api.entryPuts[0].writeEntry.description, 'third');
});

// The running order is a whole. Half of it — the songs the server has heard
// about — is not one, so what is here stands until it has all been sent.
test('a running order that is still owed is not overwritten by what a sync brings in', async () => {
  const setId = 'c9d0e1f2-a3b4-4567-8c8d-9e0f1a2b3c4d';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  await repository.saveEntry(setId, {id: 'added-at-the-gig', score_id: A_SCORE, position: 0});

  api.online = true;
  api.failEntryWith = refusal(503);
  await repository.syncWithApi();

  assert.deepEqual(repository.getSet(setId).entries.map((entry) => entry.id),
    ['added-at-the-gig', `${setId}-entry-0`],
    'a sync read the running order back over a song that had not been sent yet');
  assert.equal(repository.getSet(setId).pending_entries.length, 1);
});

test('a song the server will never take is given up on and reported', async () => {
  const setId = 'd0e1f2a3-b4c5-4678-8d9e-0f1a2b3c4d5e';
  const {repository, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();

  const problems = [];
  repository.addSyncProblemListener((problem) => problems.push(problem));

  api.online = false;
  await repository.saveEntry(setId, {score_id: 'a-score-that-was-never-uploaded'});
  api.online = true;
  api.failEntryWith = refusal(400, 'unknown_score');
  await repository.syncWithApi();

  assert.deepEqual(repository.getSet(setId).pending_entries, [],
    'it should not be retried at every sync for good');
  assert.equal(problems.length, 1, 'giving up on a song has to be said out loud');
  assert.equal(problems[0].error.errorCode, 'unknown_score');
});

test('only the owner of a set arranges it', async () => {
  const setId = 'e1f2a3b4-c5d6-4789-8e0f-1a2b3c4d5e6f';
  const {repository} = aRepository([aSet(setId, {is_owner: false})]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  await assert.rejects(() => repository.saveEntry(setId, {score_id: A_SCORE}), /someone else/);
  await assert.rejects(() => repository.deleteEntry(setId, entryId), /someone else/);
  assert.equal(repository.hasPendingChanges, false);
});

// ----------------------------------------------------------------------------
// SONGS THAT ARE NOT IN HERE
// ----------------------------------------------------------------------------

test('a song that is played from paper is part of the running order', async () => {
  const setId = 'b2c3d4e5-f6a7-4890-8b1c-2d3e4f5a6b7d';
  const {repository, database, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  const saved = await repository.saveEntry(setId, {score_id: A_SCORE});
  const withPaper = await repository.saveEntry(setId, {
    score_id: null,
    description: 'Blue Bossa — red folder',
  });

  assert.equal(withPaper.entries.length, 2);
  assert.equal(withPaper.entries[1].score_id, null);
  assert.equal(withPaper.entries[1].description, 'Blue Bossa — red folder');
  assert.equal(database.rows.get(setId).entries[1].score_id, null,
    'it should have reached the database, not just the copy in memory');
  assert.equal(saved.entries[0].score_id, A_SCORE, 'the songs that have a score keep it');

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.entryPuts.at(-1).writeEntry.score_id, null);
  assert.deepEqual(repository.getSet(setId).pending_entries, []);
});

test('a song on paper keeps having no score when something else about it is written', async () => {
  const setId = 'c3d4e5f6-a7b8-4901-8c2d-3e4f5a6b7c8e';
  const {repository} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = (await repository.saveEntry(setId, {score_id: null, description: 'the medley'}))
    .entries[0].id;

  const saved = await repository.saveEntry(setId, {id: entryId, transposition: -2});

  assert.equal(saved.entries[0].score_id, null,
    'saying what key it is played in should not have given it a score');
  assert.equal(saved.entries[0].description, 'the medley');
});

test('a song on paper is given a score when somebody uploads it', async () => {
  const setId = 'd4e5f6a7-b8c9-4012-8d3e-4f5a6b7c8d9f';
  const {repository} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = (await repository.saveEntry(setId, {score_id: null, description: 'the medley'}))
    .entries[0].id;

  const saved = await repository.saveEntry(setId, {id: entryId, score_id: A_SCORE});

  assert.equal(saved.entries[0].score_id, A_SCORE);
  assert.equal(saved.entries[0].description, 'the medley',
    'it is the same song in the same place in the gig');
});

// ----------------------------------------------------------------------------
// HOW THIS PLAYER READS IT
// ----------------------------------------------------------------------------

test('a view is stored and sent the way a set is', async () => {
  const setId = 'b7c6d5e4-f3a2-4190-8b7c-6d5e4f3a2190';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  const saved = await repository.saveEntryView(setId, entryId, {transposition: 9, hidden_parts: ['P3']});

  assert.equal(api.viewPuts.length, 1);
  assert.deepEqual(api.viewPuts[0].view, {transposition: 9, hidden_parts: ['P3'], zoom: 1});
  assert.equal(saved.entries[0].view.transposition, 9);
  assert.deepEqual(saved.pending_views, [], 'nothing should still be owed');
});

test('how big a player draws a score is part of how they read it', async () => {
  const setId = 'e5f6a7b8-c9d0-4123-8e4f-5a6b7c8d9e1a';
  const {repository, database, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  api.online = false;
  const saved = await repository.saveEntryView(setId, entryId,
    {transposition: 0, hidden_parts: [], zoom: 2.5});

  assert.equal(saved.entries[0].view.zoom, 2.5);
  assert.equal(database.rows.get(setId).entries[0].view.zoom, 2.5,
    'it should have reached the database, so the song opens that size at the gig');

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.viewPuts.at(-1).view.zoom, 2.5);
});

test('a score is read at the size it is written at until somebody says otherwise', async () => {
  const setId = 'f6a7b8c9-d0e1-4234-8f5a-6b7c8d9e1a2b';
  const {repository} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  // A set from a server that has never heard of a size, and a view written by
  // a page that says nothing about one.
  assert.equal(repository.getSet(setId).entries[0].view.zoom, 1);

  const saved = await repository.saveEntryView(setId, entryId, {transposition: 3});
  assert.equal(saved.entries[0].view.zoom, 1);
});

test('a size no score can be drawn at is brought back to one that can', async () => {
  const setId = 'a7b8c9d0-e1f2-4345-8a6b-7c8d9e1a2b3c';
  const {repository} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  // The server refuses a size outside the range, and a write that is refused is
  // an edit that was made at a gig and thrown away.
  const tooBig = await repository.saveEntryView(setId, entryId, {zoom: 99});
  assert.equal(tooBig.entries[0].view.zoom, 4);

  const tooSmall = await repository.saveEntryView(setId, entryId, {zoom: 0.01});
  assert.equal(tooSmall.entries[0].view.zoom, 0.5);
});

test('a view written with nothing at the other end is kept and sent at the next sync', async () => {
  const setId = 'c1d2e3f4-a5b6-4c78-9d0e-1f2a3b4c5d6e';
  const {repository, database, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  api.online = false;
  const saved = await repository.saveEntryView(setId, entryId, {transposition: -3, hidden_parts: ['P1']});

  assert.deepEqual(saved.pending_views, [entryId]);
  assert.equal(repository.hasPendingChanges, true);
  assert.equal(saved.entries[0].view.transposition, -3,
    'the player should read it their way at the gig, network or no network');
  assert.equal(database.rows.get(setId).entries[0].view.transposition, -3,
    'it should have reached the database, not just the copy in memory');

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.viewPuts.length, 1);
  assert.deepEqual(repository.getSet(setId).pending_views, []);
});

// A view is written against an entry of a set, so a set the server has not been
// told about yet is nothing to attach one to.
// Each is written against the one before it, so each waits for it: an entry
// against a set, a view against an entry.
test('a set, its songs and how they are read go out in that order', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;

  const set = await aSetWithOneSong(repository);
  const entryId = set.entries[0].id;
  await repository.saveEntryView(set.id, entryId, {transposition: 9, hidden_parts: []});

  api.online = true;
  await repository.syncWithApi();

  assert.equal(api.puts.length, 1, 'the set itself should have gone out');
  assert.equal(api.entryPuts.length, 1, 'then the song that was put in it');
  assert.equal(api.viewPuts.length, 1, 'and then how it is read');
  assert.equal(api.entryPuts[0].entryId, entryId);
  assert.equal(api.viewPuts[0].entryId, entryId,
    'the view should point at the entry that was written');
  assert.equal(repository.hasPendingChanges, false);
});

test('a song and its view stay queued while the set they are in cannot be sent', async () => {
  const {repository, api} = aRepository();
  await repository.init();
  api.online = false;

  const set = await aSetWithOneSong(repository);
  await repository.saveEntryView(set.id, set.entries[0].id, {transposition: 9, hidden_parts: []});

  api.online = true;
  api.failPutWith = refusal(503);
  await repository.syncWithApi();

  assert.equal(api.entryPuts.length, 0,
    'a song was written into a set the server has never been told about');
  assert.equal(api.viewPuts.length, 0,
    'a view was written against an entry the server has never been told about');
  assert.deepEqual(repository.getSet(set.id).pending_views, [set.entries[0].id]);
  assert.equal(repository.getSet(set.id).pending_entries.length, 1);
});

test('a view stays queued while the song it is of cannot be sent', async () => {
  const setId = 'ab12cd34-ef56-4789-8abc-def012345678';
  const {repository, api} = aRepository([aSet(setId, {entries: []})]);
  await repository.init();
  await repository.syncWithApi();

  api.online = false;
  const set = await repository.saveEntry(setId, {score_id: A_SCORE});
  const entryId = set.entries[0].id;
  await repository.saveEntryView(setId, entryId, {transposition: 9, hidden_parts: []});

  api.online = true;
  api.failEntryWith = refusal(503);
  await repository.syncWithApi();

  assert.equal(api.viewPuts.length, 0,
    'a view was written against an entry the server has never been told about');
  assert.deepEqual(repository.getSet(setId).pending_views, [entryId]);
});

// The same rule as for a set: what was written here wins until it has been
// pushed, because it was written after the last thing the server said.
test('a view that is still owed is not overwritten by what a sync brings in', async () => {
  const setId = 'e5f6a7b8-c9d0-4e1f-8a2b-3c4d5e6f7a8b';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  api.online = false;
  await repository.saveEntryView(setId, entryId, {transposition: 7, hidden_parts: ['P2']});

  // The network is back, but the view still cannot get through.
  api.online = true;
  api.failViewWith = refusal(503);
  await repository.syncWithApi();

  const set = repository.getSet(setId);
  assert.equal(set.entries[0].view.transposition, 7,
    'a sync read a view back over one that had not been sent yet');
  assert.deepEqual(set.entries[0].view.hidden_parts, ['P2']);
  assert.deepEqual(set.pending_views, [entryId]);
});

// Writing the set is the owner saying what the band does, and it says nothing
// about how anybody reads it.
test('writing the set leaves a view that has not been sent alone', async () => {
  const setId = 'f6a7b8c9-d0e1-4f2a-8b3c-4d5e6f7a8b9c';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  api.online = false;
  await repository.saveEntryView(setId, entryId, {transposition: 5, hidden_parts: []});
  const set = repository.getSet(setId);
  await repository.saveSet({
    id: setId,
    title: 'Renamed',
    description: set.description,
    shared_with: set.shared_with,
    entries: set.entries,
  });

  api.online = true;
  await repository.syncWithApi();

  const saved = repository.getSet(setId);
  assert.equal(saved.title, 'Renamed');
  assert.equal(saved.entries[0].view.transposition, 5, 'renaming the set threw away how it is read');
  assert.equal(api.viewPuts.length, 1);
});

// A view of an entry that is not in the set any more is about a song that is no
// longer played.
test('a view of an entry that has been taken out of the set is dropped', async () => {
  const setId = 'a7b8c9d0-e1f2-4a3b-8c4d-5e6f7a8b9c0d';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  api.online = false;
  await repository.saveEntryView(setId, entryId, {transposition: 5, hidden_parts: []});
  await repository.deleteEntry(setId, entryId);

  api.online = true;
  await repository.syncWithApi();

  assert.deepEqual(repository.getSet(setId).pending_views, []);
  assert.equal(api.viewPuts.length, 0, 'a view was sent for an entry that is no longer played');
});

test('a view the server will never take is given up on and reported', async () => {
  const setId = 'b8c9d0e1-f2a3-4b4c-8d5e-6f7a8b9c0d1e';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  const problems = [];
  repository.addSyncProblemListener((problem) => problems.push(problem));

  api.online = false;
  await repository.saveEntryView(setId, entryId, {transposition: 5, hidden_parts: []});
  api.online = true;
  api.failViewWith = refusal(404, 'set_entry_not_found');
  await repository.syncWithApi();

  assert.deepEqual(repository.getSet(setId).pending_views, [],
    'it should not be retried at every sync for good');
  assert.equal(problems.length, 1, 'giving up on how somebody reads a song has to be said out loud');
  assert.equal(problems[0].action, 'view');
});

// ----------------------------------------------------------------------------
// WHAT IS NOT OURS TO CHANGE
// ----------------------------------------------------------------------------

// There is no moment later at which the server would take it, so queueing it
// would only be a longer way of refusing.
test('a set that is only shared with this user cannot be written or deleted', async () => {
  const setId = '0f1e2d3c-4b5a-4968-8776-5a4b3c2d1e0f';
  const {repository} = aRepository([aSet(setId, {is_owner: false, shared_with: []})]);
  await repository.init();
  await repository.syncWithApi();

  await assert.rejects(() => repository.saveSet(aDraft({id: setId})), /someone else/);
  await assert.rejects(() => repository.deleteSet(setId), /someone else/);
  assert.equal(repository.hasPendingChanges, false);
});

// The whole point of a view being the player's rather than the set's: the
// pianist reads a set somebody else built, and how they read it is theirs.
test('a set that is only shared with this user is still read this user\'s way', async () => {
  const setId = '1e2d3c4b-5a69-4887-965a-4b3c2d1e0f19';
  const {repository, api} = aRepository([aSet(setId, {is_owner: false, shared_with: []})]);
  await repository.init();
  await repository.syncWithApi();
  const entryId = repository.getSet(setId).entries[0].id;

  const saved = await repository.saveEntryView(setId, entryId, {transposition: -5, hidden_parts: ['P1']});

  assert.equal(saved.entries[0].view.transposition, -5);
  assert.deepEqual(saved.entries[0].view.hidden_parts, ['P1']);
  assert.equal(api.viewPuts.length, 1, 'a player was not allowed to say how they read somebody else\'s set');
});

// ----------------------------------------------------------------------------
// THE CHANGE WINDOW
// ----------------------------------------------------------------------------

test('a sync asks about everything the first time and about the rest after that', async () => {
  const setId = '7e6d5c4b-3a29-4f18-9e0d-7c6b5a4f3e2d';
  const {repository, api} = aRepository([aSet(setId)]);
  await repository.init();

  await repository.syncWithApi();
  assert.equal(api.listedWindows[0].since, null, 'the first sync should ask about everything there is');

  const syncedAt = repository.getSet(setId).last_synced_at;
  await repository.syncWithApi();
  assert.deepEqual(api.listedWindows[1].since, syncedAt,
    'the next window should start where the server last said anything');
});

test('the moments a set carries are dates, not the strings they arrive as', async () => {
  const setId = '5d4c3b2a-1f0e-4d9c-8b7a-6f5e4d3c2b1a';
  const {repository} = aRepository([aSet(setId, {last_changed_at: '2026-08-01T12:00:00.000Z'})]);
  await repository.init();

  await repository.syncWithApi();

  const set = repository.getSet(setId);
  assert.ok(set.last_changed_at instanceof Date);
  assert.equal(set.last_changed_at.toISOString(), '2026-08-01T12:00:00.000Z');
});

test('what was synced is read back the same way after a restart', async () => {
  const setId = '2a3b4c5d-6e7f-4809-9a1b-2c3d4e5f6071';
  const {repository, database, api} = aRepository([aSet(setId)]);
  await repository.init();
  await repository.syncWithApi();

  const restarted = new SetsRepository(database, api, new FakeOidc(api));
  await restarted.init();

  assert.equal(restarted.sets.length, 1);
  assert.equal(restarted.getSet(setId).entries[0].transposition, -2);
});

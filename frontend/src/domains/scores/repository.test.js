import test from 'node:test';
import assert from 'node:assert/strict';

import {ScoresRepository} from './repository.js';

// ----------------------------------------------------------------------------
// STAND-INS
// ----------------------------------------------------------------------------

/** The database, as far as the repository can tell: rows kept in a map. */
class FakeDatabase {
  rows = new Map();

  async fetchScores() {
    return Array.from(this.rows.values());
  }

  async saveScore(score) {
    this.rows.set(score.id, score);
  }

  async saveScores(scores) {
    for (const score of scores) {
      this.rows.set(score.id, score);
    }
  }
}

/** Where the documents are kept, as far as the repository can tell. */
class FakeStorage {
  files = new Map();

  async exists(scoreId) {
    return this.files.has(scoreId);
  }

  async get(scoreId) {
    return this.files.get(scoreId);
  }

  async save(scoreId, musicxml) {
    this.files.set(scoreId, musicxml);
  }
}

class FakeOidc {
  async canBeReached() {
    return true;
  }

  async getActiveAccessToken() {
    return 'a-token';
  }
}

/**
 * The API, holding whatever the server is meant to know about.
 *
 * `getScores` answers the way the real one does — only what changed inside the
 * window it is given — which is the whole reason a score can go missing.
 */
class FakeApi {
  /** @param scores {object[]} */
  constructor(scores) {
    this.scores = scores;
    this.musicxml = new Map();
    this.getScoreCalls = [];
    this.failMusicxmlFor = null;
  }

  async canBeReached() {
    return true;
  }

  async getScores(changesSince, changesUntil) {
    return this.scores.filter((score) => {
      const changedAt = new Date(score.last_changed_at);
      return (changesSince == null || changedAt >= changesSince)
        && (changesUntil == null || changedAt <= changesUntil);
    });
  }

  async getScore(scoreId) {
    this.getScoreCalls.push(scoreId);
    return this.scores.find((score) => score.id === scoreId) ?? null;
  }

  async getScoreMusicxml(scoreId) {
    if (this.failMusicxmlFor === scoreId) {
      throw new Error('the document could not be fetched');
    }
    return this.musicxml.get(scoreId) ?? '<score-partwise/>';
  }
}

/**
 * @param id {string}
 * @param lastChangedAt {string}
 */
function aScore(id, lastChangedAt) {
  return {
    id,
    work: {title: 'Work title', number: 'Op. 1'},
    movement: {title: '', number: ''},
    creators: {composers: ['Clara Composer'], lyricists: []},
    languages: ['nl'],
    instruments: ['voice.vocals'],
    last_changed_at: lastChangedAt,
    tags: [],
  };
}

/**
 * A score as it sits in the local database: the moments already dates, and the
 * three the app keeps for itself filled in.
 *
 * @param id {string}
 * @param moments {{lastChangedAt: string, lastSyncedAt: string, lastFetchedFileAt?: string}}
 */
function storedScore(id, moments) {
  return {
    ...aScore(id, moments.lastChangedAt),
    last_changed_at: new Date(moments.lastChangedAt),
    last_synced_at: new Date(moments.lastSyncedAt),
    last_fetched_file_at: moments.lastFetchedFileAt == null
      ? null
      : new Date(moments.lastFetchedFileAt),
    last_viewed_at: null,
  };
}

/**
 * A repository with nothing stored locally and the given scores on the server.
 *
 * @param scores {object[]}
 */
function aRepository(scores) {
  const database = new FakeDatabase();
  const api = new FakeApi(scores);
  const storage = new FakeStorage();
  const repository = new ScoresRepository(database, api, new FakeOidc(), storage);
  return {repository, database, api, storage};
}

// ----------------------------------------------------------------------------
// TESTS
// ----------------------------------------------------------------------------

// This is the state the app actually got into: the document of a score cached
// on disk, the score itself missing from the local database, and every sync
// from then on asking only about what changed after the last one — a window the
// missing score is too old to fall into. Nothing brings it back, so opening it
// fails the same way on every reload.
test('a score that is too old for the sync window is fetched by id instead', async () => {
  const scoreId = 'de003c9b-0e2b-4b0d-836a-32c691082189';
  const missing = aScore(scoreId, '2026-01-01T00:00:00.000Z');
  const known = aScore('a-score-that-did-make-it', '2026-08-04T12:00:00.000Z');
  const {repository, database, api, storage} = aRepository([missing, known]);

  // This app has synced before, so it only ever asks about what changed since
  // then — and the missing score last changed long before that.
  await database.saveScore(storedScore(known.id, {
    lastChangedAt: '2026-08-04T12:00:00.000Z',
    lastSyncedAt: '2026-08-04T12:00:00.000Z',
  }));
  await repository.init();
  await repository.syncWithApi();

  assert.ok(!repository.scores.some((score) => score.id === scoreId),
    'a sync should not have been able to reach the missing score');

  // The document is on disk from an earlier visit; the score itself is not.
  await storage.save(scoreId, '<score-partwise/>');

  await repository.updateScoreLastViewedAt(scoreId);

  assert.deepEqual(api.getScoreCalls, [scoreId],
    'a score the sync window cannot reach should be asked for by its id');
  assert.ok(repository.scores.some((score) => score.id === scoreId),
    'the score should be known once it has been fetched');
});

test('viewing a score whose document is cached but whose metadata is missing does not throw', async () => {
  const scoreId = 'de003c9b-0e2b-4b0d-836a-32c691082189';
  const {repository, storage} = aRepository([aScore(scoreId, '2026-01-01T00:00:00.000Z')]);
  await repository.init();
  await storage.save(scoreId, '<score-partwise/>');

  const musicxml = await repository.getMusicXml(scoreId);
  await repository.updateScoreLastViewedAt(scoreId);

  assert.equal(musicxml, '<score-partwise/>');
  const score = repository.scores.find((score) => score.id === scoreId);
  assert.ok(score != null, 'handing over the document should have placed the score it belongs to');
  assert.ok(score.last_viewed_at instanceof Date, 'the score should have been marked as viewed');
});

test('a score that does not exist is still an error', async () => {
  const {repository} = aRepository([]);
  await repository.init();

  await assert.rejects(
    () => repository.updateScoreLastViewedAt('a-score-that-was-never-uploaded'),
    /not found/);
});

// The document and the metadata are two caches of the same thing, and the one
// that cannot be recovered is the metadata: a sync only ever asks about what
// changed since the last one. So it is written first, and a document that fails
// to cache costs a download rather than a score.
test('a document that cannot be cached does not cost the metadata of the whole sync', async () => {
  const firstId = 'first-score';
  const secondId = 'second-score';
  const {repository, database, api, storage} = aRepository([
    aScore(firstId, '2026-08-04T00:00:00.000Z'),
    aScore(secondId, '2026-08-04T00:00:01.000Z'),
  ]);

  // Both are scores this app already has the documents of, last synced before
  // they changed — so the next sync refreshes both, and one download fails.
  for (const id of [firstId, secondId]) {
    await storage.save(id, '<old/>');
    await database.saveScore(storedScore(id, {
      lastChangedAt: '2026-07-01T00:00:00.000Z',
      lastSyncedAt: '2026-07-01T00:00:00.000Z',
      lastFetchedFileAt: '2026-07-01T00:00:00.000Z',
    }));
  }
  await repository.init();
  api.failMusicxmlFor = secondId;

  await assert.rejects(() => repository.syncWithApi());

  // What the sync learned has to have reached the database, not just the copy
  // in memory: the metadata is what a later sync can no longer ask for.
  const changedAt = new Date('2026-08-04T00:00:00.000Z');
  assert.deepEqual(database.rows.get(firstId).last_changed_at, changedAt,
    'the score whose document was fetched should have been saved as it now is');
  assert.deepEqual(database.rows.get(secondId).last_changed_at,
    new Date('2026-08-04T00:00:01.000Z'),
    'a score should be saved even when its document could not be fetched');
});

test('the moments a score carries are dates, not the strings they arrive as', async () => {
  const scoreId = 'a-score';
  const {repository} = aRepository([aScore(scoreId, '2026-08-01T00:00:00.000Z')]);

  await repository.init();
  await repository.syncWithApi();

  const score = repository.scores.find((score) => score.id === scoreId);
  assert.ok(score.last_changed_at instanceof Date,
    'last_changed_at decides whether a cached document is stale, so it has to compare as a date');
  assert.equal(score.last_changed_at.toISOString(), '2026-08-01T00:00:00.000Z');
});

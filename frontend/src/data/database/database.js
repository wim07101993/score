/**
 * @callback ScoresChangedCallback
 */

export const ObjectStoreName = Object.freeze({
  Scores: 'scores'
})

export class Database {
  /**
   * @type {IDBDatabase}
   * @private
   */
  _database = null;

  /**
   * @type {Object<String, Score>}
   * @private
   */
  _scores = {};

  /**
   * @type {ScoresChangedCallback[]}
   * @private
   */
  _scoresChangesListeners = []

  /** @type {Score[]} */
  get scores() {
    return Object.values(this._scores);
  }

  async connect() {
    this._database = await _openDatabase();
    const scores = await _fetchScoresFromDb(this._database);
    for (let score of scores) {
      this._scores[score.id] = score;
    }
  }

  dispose() {
    this._database.close();
  }

  /**
   * Adds the given scores to the database. If scores with the same keys already exist, it is only saved if the change
   * date is after the existing score's change date.
   *
   * @param scores {Score[]}
   */
  async addScores(scores) {
    for (let score of scores) {
      const existing = this._scores[score.id];
      if (existing != null && existing.last_changed_at > score.last_changed_at) {
        continue;
      }
      this._scores[score.id] = score;
    }
    await _addScoresToDb(this._database, scores);
    this._notifyScoresChangesListeners();
  }

  /**
   * Retrieves a score from the database. If there is no score with the given id, null is returned.
   *
   * @param id {String}
   * @returns {Score|null}
   */
  getScore(id) {
    return this._scores[id];
  }

  /** @param listener {ScoresChangedCallback} */
  addScoreChangesListener(listener) {
    this._scoresChangesListeners.push(listener);
  }

  /** @param listener {ScoresChangedCallback} */
  removeScoreChangesListener(listener) {
    const index = this._scoresChangesListeners.indexOf(listener);
    if (index < 0) {
      return;
    }
    this._scoresChangesListeners.splice(index, 1);
  }

  _notifyScoresChangesListeners() {
    for (let listener of this._scoresChangesListeners) {
      listener();
    }
  }
}

/**
 * @type {Promise<IDBDatabase>}
 * @private
 */
function _openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('scores', 1);

    request.onerror = (event) => reject(event.target.error)
    request.onsuccess = (event) => resolve(event.target.result)

    request.onupgradeneeded = (event) => {
      console.log(`upgrade needed from version ${event.oldVersion} to ${event.newVersion}`, event);
      const db = event.target.result;

      if (!db.objectStoreNames.contains(ObjectStoreName.Scores)) {
        const store = db.createObjectStore(ObjectStoreName.Scores, {
          keyPath: 'id',
          autoIncrement: false
        });
        console.log(`created ${store.name} store`);
      }
    }
  });
}

/**
 * @returns {Promise<Score[]>}
 * @private
 */
async function _fetchScoresFromDb(database) {
  return new Promise((resolve, reject) => {
    const request = database
      .transaction([ObjectStoreName.Scores])
      .objectStore(ObjectStoreName.Scores)
      .getAll();

    request.onerror = (event) => reject(event.target.result);
    request.onsuccess = (event) => resolve(event.target.result)
  })
}

/**
 * @param {IDBDatabase} database
 * @param {Score[]} scores
 * @returns {Promise<void>}
 * @private
 */
async function _addScoresToDb(database, scores) {
  const transaction = await database.transaction(ObjectStoreName.Scores, 'readwrite');
  const store = transaction.objectStore(ObjectStoreName.Scores);
  const transactionCompletePromise = new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve();
    transaction.onerror = (event) => reject(event);
    transaction.onabort = (event) => reject(event);
  });

  for (const score of scores) {
    store.put(score);
  }

  await transactionCompletePromise;
}

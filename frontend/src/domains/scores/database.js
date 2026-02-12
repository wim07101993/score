export const ObjectStoreName = Object.freeze({
  Scores: 'scores'
})

export class ScoreDatabase {
  /**
   * @type IDBDatabase
   */
  database;

  /**
   * @return {Promise<void>}
   */
  async open() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('scores', 1);

      request.onerror = (event) => reject(event.target.error)
      request.onsuccess = event => {
        this.database = event.target.result;
        return resolve();
      }

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
   */
  async fetchScores() {
    return new Promise((resolve, reject) => {
      const request = this.database
        .transaction([ObjectStoreName.Scores])
        .objectStore(ObjectStoreName.Scores)
        .getAll();

      request.onerror = (event) => reject(event.target.result);
      request.onsuccess = (event) => resolve(event.target.result)
    })
  }

  /**
   * @param {Score[]} scores
   * @returns {Promise<void>}
   */
  async saveScores(scores) {
    const transaction = await this.database.transaction(ObjectStoreName.Scores, 'readwrite');
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

  /**
   * @param {Score} score
   * @returns {Promise<void>}
   */
  async saveScore(score) {
    const transaction = await this.database.transaction(ObjectStoreName.Scores, 'readwrite');
    const store = transaction.objectStore(ObjectStoreName.Scores);
    const transactionCompletePromise = new Promise((resolve, reject) => {
      transaction.oncomplete = () => resolve();
      transaction.onerror = (event) => reject(event);
      transaction.onabort = (event) => reject(event);
    });

    store.put(score);

    await transactionCompletePromise;
  }
}

// ----------------------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------------------

export class Score {
  /**
   * @param {string} id
   * @param {Work|null} work
   * @param {Movement|null} movement
   * @param {Creators} creators
   * @param {string[]} languages
   * @param {string[]} instruments
   * @param {Date} last_changed_at
   * @param {string[]} tags
   * @param {Date|null} last_synced_at
   * @param {Date|null} last_fetched_file_at
   * @param {Date|null} last_viewed_at
   */
  constructor(id,
              work,
              movement,
              creators,
              languages,
              instruments,
              last_changed_at,
              tags,
              last_synced_at,
              last_fetched_file_at,
              last_viewed_at) {
    this.id = id;
    this.work = work;
    this.movement = movement;
    this.creators = creators;
    this.languages = languages;
    this.instruments = instruments;
    this.last_changed_at = last_changed_at;
    this.tags = tags;
    this.last_synced_at = last_synced_at;
    this.last_fetched_file_at = last_fetched_file_at;
    this.last_viewed_at = last_viewed_at;
  }
}

export class Movement {
  /**
   * @param {string|null} title
   * @param {bigint|null} number
   */
  constructor(title, number) {
    this.title = title;
    this.number = number;
  }
}

export class Work {
  /**
   * @param {string|null} title
   * @param {bigint|null} number
   */
  constructor(title, number) {
    this.title = title;
    this.number = number;
  }
}

export class Creators {
  /**
   * @param {string[]} composers
   * @param {string[]} lyricists
   */
  constructor(composers, lyricists) {
    this.composers = composers;
    this.lyricists = lyricists;
  }
}

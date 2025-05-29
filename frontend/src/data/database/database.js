export const ObjectStoreName = Object.freeze({
  Scores: 'scores'
})


/**
 * @type {IDBDatabase|null}
 */
let database = null;

/**
 * Opens the score database.
 *
 * @returns {Promise<IDBDatabase>}
 */
export async function getDatabase() {
  if (database != null) {
    return database;
  }
  return await new Promise((resolve, reject) => {
    console.log('opening score database');
    const request = indexedDB.open('scores', 1);

    request.onerror = (event) => {
      console.log(`failed to open score database`, event.target.error);
      reject(event.target.error);
    }

    request.onsuccess = (event) => {
      console.log(`opened score database`, event);
      database = event.target.result;
      resolve(event.target.result);
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
 * @returns {Promise<Score[]>} returns a list of all the scores in the database.
 */
export async function getAllScores() {
  console.log('getting all scores');
  const request = await getDatabase()
    .then((database) => database
      .transaction([ObjectStoreName.Scores])
      .objectStore(ObjectStoreName.Scores)
      .getAll());

  return await new Promise((resolve, reject) => {
    request.onerror = (event) => {
      console.log('failed to get scores', event);
      reject(event.target.result);
    };

    request.onsuccess = (event) => {
      /**
       * @type {Score[]}
       */
      let scores = event.target.result
      resolve(scores);
    }
  })
}

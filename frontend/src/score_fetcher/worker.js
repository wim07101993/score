import {ScoreFetcherCommand} from "./message.js";
import {getDatabase, ObjectStoreName} from "../database/database.js";
import {Score, Work} from "../database/models.js";

self.onmessage = async (event) => {
  /**
   * @type {ScoreFetcherMessage}
   */
  const message = event.data;
  switch (message.command) {
    case ScoreFetcherCommand.StartFetching:
      console.log('Start fetching scores');
      await fetchScores()
      break;

    default:
      console.log(`Unknown message:`, message.command);
      break;
  }
}

/**
 * @returns {Promise<Score[]>}
 */
async function fetchScores() {
  // TODO actually fetch scores and save them to the database.

  const db = await getDatabase();
  const transaction = await db.transaction(ObjectStoreName.Scores, 'readwrite');
  const store = transaction.objectStore(ObjectStoreName.Scores);
  const transactionCompletePromise = new Promise((resolve, reject) => {
    transaction.oncomplete = (event) => {
      console.log('DB transaction completed:', event);
      resolve();
    };

    transaction.onerror = (event) => {
      console.log('DB transaction failed:', event);
      reject(event);
    };

    transaction.onabort = (event) => {
      console.log('DB transaction aborted:', event);
      reject(event);
    };
  });

  store.put(new Score(
    'id',
    new Work('Hello world', null),
    null,
    ['John doe'],
    ['nl'],
    ['guitar'],
    new Date(2003, 2, 1),
    ['funny', 'demo']
  ));

  await transactionCompletePromise;
}


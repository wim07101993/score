import {ScoreFetcherCommand, ScoreFetcherMessage, ScoresEvent} from "./message.js";
import {getDatabase, ObjectStoreName} from "../database/database.js";
import {Score} from "../database/models.js";

self.onmessage = async (event) => {
  /**
   * @type {ScoreFetcherMessage}
   */
  const message = event.data;
  switch (message.command) {
    case ScoreFetcherCommand.StartUpdatingScores:
      console.log('Start fetching scores');
      await updateScores();
      self.postMessage(new ScoreFetcherMessage(ScoresEvent.ScoresFetched));
      break;

    default:
      console.log(`Unknown message:`, message.command);
      break;
  }
}

async function updateScores() {
  const scores = await getScoresFromApi();
  await saveScores(scores);
}

/**
 * @returns {Promise<Score[]>}
 */
async function getScoresFromApi() {
  const changesSince = '20000101T000000';
  const today = new Date();
  const changesUntil = today.toISOString()
    .replaceAll('-', '')
    .replaceAll(':', '')
    .split('.')[0];

  /**
   * @type Response
   */
  const response = await fetch(`http://localhost:7001/scores?Changes-Since=${changesSince}&Changes-Until=${changesUntil}`)
  if (response.status >= 500) {
    throw `failed to fetch scores (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
  } else if (response.status >= 400) {
    throw `failed to fetch scores: ${response.status} ${response.statusText}: ${await response.text()}`;
  }

  return await response.json();
}

/**
 * @param {Score[]} scores the scores to save in the database
 * @returns {Promise<void>}
 */
async function saveScores(scores) {
  const db = await getDatabase();
  const transaction = await db.transaction(ObjectStoreName.Scores, 'readwrite');
  const store = transaction.objectStore(ObjectStoreName.Scores);
  const transactionCompletePromise = new Promise((resolve, reject) => {
    transaction.oncomplete = (event) => {
      console.log('DB transaction completed:', event);
      resolve();
    };

    transaction.onerror = (event) => {
      console.error('DB transaction failed:', event);
      reject(event);
    };

    transaction.onabort = (event) => {
      console.log('DB transaction aborted:', event);
      reject(event);
    };
  });

  for (const score of scores) {
    store.put(score);
  }

  await transactionCompletePromise;
}

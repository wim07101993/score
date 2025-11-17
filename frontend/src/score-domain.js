import {Creators, Movement, Score, Work} from "./data/database.js";
import {saveMusicxml} from "./data/storage.js";
import {scoresApi, oidcService, database} from "./globals.js";


/**
 * @Type {Promise<void>}
 */
let initialization;

export async function initializeScoreApp() {
  if (initialization == null) {
    initialization = async function () {
      await database.connect();
    }()
  }
  await initialization;
}

export async function fetchScoreUpdates() {
  await initializeScoreApp();
  await updateScoreDb();
  await updateScoreFiles();
}

async function updateScoreDb() {
  let newestScore = null;
  if (database.scores.length > 0) {
    newestScore = database.scores.reduce(
      (newest, score) => score.last_changed_at > newest.last_changed_at ? score : newest
    );
  }
  const lastFetchDate = newestScore?.last_changed_at ?? new Date(2000);

  const accessToken = await oidcService.authorize();
  if (accessToken == null) {
    return;
  }
  const newScoreDtos = await scoresApi.getScores(lastFetchDate, new Date(), accessToken);
  const newScores = newScoreDtos.map((score) => new Score(
    score.id,
    score.work == null ? null : new Work(score.work.title, score.work.number),
    score.movement == null ? null : new Movement(score.movement.title, score.movement.number),
    new Creators(
      score.creators.composers,
      score.creators.lyricists
    ),
    score.languages,
    score.instruments,
    new Date(score.last_changed_at),
    score.tags,
    database.getScore(score.id)?.last_fetched_file_at
  ));
  await database.addScores(newScores);
}

async function updateScoreFiles() {
  const dir = await navigator.storage.getDirectory();
  for await (const [_, value] of dir.entries()) {
    const filename = value.name.toString();

    const scoreId = filename.substring(0, filename.length - '.musicxml'.length);
    const score = database.getScore(scoreId);

    if (score == null) {
      await dir.removeEntry(filename);
      continue;
    }

    if (score.last_fetched_file_at != null && score.last_changed_at <= score.last_fetched_file_at) {
      continue;
    }

    const accessToken = await oidcService.authorize();
    if (accessToken == null) {
      return;
    }
    const musicxml = await scoresApi.getScoreMusicxml(scoreId, accessToken);
    await saveMusicxml(scoreId, musicxml);
    score.last_fetched_file_at = new Date();

    await database.addScore(score);
  }
}

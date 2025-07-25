import {Database} from "./data/database/database.js";
import {ScoresApi} from "./data/api/scores-api.js";
import {authorize} from "./data/auth/auth.js";
import {Creators, Movement, Score, Work} from "./data/database/models.js";
import {saveMusicxml} from "./data/database/storage.js";

export class AppState {
  constructor() {
    this.database = new Database();
    this.api = new ScoresApi();
    this.initialization = this._initialize();
  }

  async _initialize() {
    await this.database.connect();
    return this;
  }

  async fetchScoreUpdates() {
    await this.initialization;
    await this._updateScoreDb();
    await this._updateScoreFiles();
  }

  async _updateScoreDb() {
    let newestScore = null;
    if (this.database.scores.length > 0) {
      newestScore = this.database.scores.reduce(
        (newest, score) => score.last_changed_at > newest.last_changed_at ? score : newest
      );
    }
    const lastFetchDate = newestScore?.last_changed_at ?? new Date(2000);

    const accessToken = await authorize();
    if (accessToken == null) {
      return;
    }
    const newScoreDtos = await this.api.getScores(lastFetchDate, new Date(), accessToken);
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
      this.database.getScore(score.id)?.last_fetched_file_at
    ));
    await this.database.addScores(newScores);
  }

  async _updateScoreFiles() {
    const dir = await navigator.storage.getDirectory();
    for await (const [_, value] of dir.entries()) {
      const filename = value.name.toString();

      const scoreId = filename.substring(0, filename.length - '.musicxml'.length);
      const score = this.database.getScore(scoreId);

      if (score == null) {
        await dir.removeEntry(filename);
        continue;
      }

      if (score.last_fetched_file_at != null && score.last_changed_at <= score.last_fetched_file_at) {
        continue;
      }

      const accessToken = await authorize();
      if (accessToken == null) {
        return;
      }
      const musicxml = await this.api.getScoreMusicxml(scoreId, accessToken);
      await saveMusicxml(scoreId, musicxml);
      score.last_fetched_file_at = new Date();

      await this.database.addScore(score);
    }
  }
}

export const appState = new AppState();

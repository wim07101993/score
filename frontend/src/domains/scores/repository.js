import {Creators, Movement, Score, ScoreDatabase, Work} from "./database.js";
import {ScoresApi} from "./api.js";
import {OidcApi} from "../auth/oidc-api.js";
import {MusicXmlStorage} from "./storage.js";

/**
 * @typedef {function()} ScoresChangedCallback
 */

export class ScoresRepository {
  /**
   * @param database {ScoreDatabase}
   * @param api {ScoresApi}
   * @param oidc {OidcApi}
   */
  constructor(database, api, oidc) {
    this._database = database;
    this._api = api;
    this._oidc = oidc;
  }

  /**
   * @type {Map<String, Score>}
   * @private
   */
  _scores = new Map();

  /**
   * @type {ScoresChangedCallback[]}
   * @private
   */
  _scoresChangesListeners = []

  /** @type {Score[]} */
  get scores() {
    return Object.values(this._scores);
  }

  async init() {
    const scores = await this._database.fetchScores();
    for (let score of scores) {
      this._scores[score.id] = score;
    }
  }

  async syncWithApi() {
    console.log('syncing api scores with local scores')
    let lastSyncDate = null;
    for (let score of Object.values(this._scores)) {
      if (lastSyncDate == null) {
        lastSyncDate = score.last_synced_at;
      }
      if (score.last_synced_at > lastSyncDate) {
        lastSyncDate = score.last_synced_at;
      }
    }
    const authToken = await this._oidc.getActiveAccessToken();
    const fromApi = await this._api.getScores(lastSyncDate, new Date(), authToken)
    if (fromApi.length === 0) {
      return;
    }

    const toUpdate = fromApi.map((score) => {
      return new Score(
        score.id,
        score.work == null ? null : new Work(score.work.title, score.work.number),
        score.movement == null ? null : new Movement(score.movement.title, score.movement.number),
        score.creators == null ? null : new Creators(score.creators.composers, score.creators.lyricists),
        score.languages,
        score.instruments,
        score.last_changed_at,
        score.tags,
        new Date(),
        this._scores[score.id]?.last_fetched_file_at,
        this._scores[score.id]?.last_viewed_at,
      );
    });

    for (const score of toUpdate.filter((score) => score.last_fetched_file_at != null)) {
      if (score.last_fetched_file_at != null
        && score.last_changed_at <= score.last_fetched_file_at) {
        continue;
      }

      const accessToken = await this._oidc.getActiveAccessToken();
      const musicxml = await this._api.getScoreMusicxml(score.id, accessToken);
      await MusicXmlStorage.save(score.id, musicxml);
      score.last_fetched_file_at = new Date();
    }

    await this._addScoresFromApi(toUpdate);
  }

  /**
   * Adds the given scores to the database. If scores with the same keys already exist, it is only saved if the change
   * date is after the existing score's change date.
   *
   * @param scores {Score[]}
   * @private
   */
  async _addScoresFromApi(scores) {
    let toSave = [];

    for (let score of scores) {
      const existing = this._scores[score.id];
      if (existing != null && existing.last_changed_at > score.last_changed_at) {
        continue;
      }
      toSave.push(score);
      this._scores[score.id] = score;
    }

    if (toSave.length === 0) {
      return;
    }

    await this._database.saveScores(toSave);
    this._notifyScoresChangesListeners();
  }

  /**
   * @param scoreId
   */
  async getMusicXml(scoreId) {
    let musicxml;

    if (await MusicXmlStorage.exists(scoreId)) {
      musicxml = await MusicXmlStorage.get(scoreId);
    }
    if (musicxml != null) {
      return musicxml
    }

    if (!await this._api.canBeReached() || !await this._oidc.canBeReached()) {
      return null;
    }

    const accessToken = await this._oidc.getActiveAccessToken();
    musicxml = await this._api.getScoreMusicxml(scoreId, accessToken);
    if (musicxml == null) {
      alert('failed to load music xml');
      return;
    }

    let score = this._scores[scoreId];
    if (score == null) {
      await this.syncWithApi();
    }

    score = this._scores[scoreId];
    if (score == null){
      alert('Could not find a score but did find a musicxml. This should not happen');
      return musicxml;
    }
    score.last_fetched_file_at = new Date();
    await this._database.saveScore(score);
    await MusicXmlStorage.save(scoreId, musicxml);
    return musicxml;
  }

  /**
   * Sets the `lastViewedAt` to "now" for the score with the given id. If the score doesn't exist, an error is thrown.
   *
   * @param scoreId {String}
   * @returns {Promise<void>}
   */
  async updateScoreLastViewedAt(scoreId) {
    for (let score of this.scores) {
      if (score.id === scoreId) {
        score.last_viewed_at = new Date();
        await this._database.saveScore(score);
        this._notifyScoresChangesListeners();
        return;
      }
    }
    throw new Error(`Score with id '${scoreId}' not found`)
  }

  /** @param listener {ScoresChangedCallback} */
  addScoreChangesListener(listener) {
    this._scoresChangesListeners.push(listener);
  }

  _notifyScoresChangesListeners() {
    for (let listener of this._scoresChangesListeners) {
      listener();
    }
  }
}

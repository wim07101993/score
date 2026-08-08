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
   * @param storage {typeof MusicXmlStorage} where the documents are kept. Only
   *   passed in by the tests, which have no browser storage to keep them in.
   */
  constructor(database, api, oidc, storage = MusicXmlStorage) {
    this._database = database;
    this._api = api;
    this._oidc = oidc;
    this._storage = storage;
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
    return Array.from(this._scores.values());
  }

  async init() {
    const scores = await this._database.fetchScores();
    for (let score of scores) {
      this._scores.set(score.id, score);
    }
  }

  async syncWithApi() {
    console.log('syncing api scores with local scores')
    let lastSyncDate = null;
    for (let score of this._scores.values()) {
      if (lastSyncDate == null) {
        lastSyncDate = score.last_synced_at;
      }
      if (score.last_synced_at > lastSyncDate) {
        lastSyncDate = score.last_synced_at;
      }
    }
    const authToken = await this._oidc.getActiveAccessToken();
    const fromApi = await this._api.getScores(lastSyncDate, new Date(), authToken);
    if (fromApi.length === 0) {
      return;
    }

    const toUpdate = fromApi.map((score) => this._scoreFromApi(score));

    await this._addScoresFromApi(toUpdate);

    for (const score of toUpdate.filter((score) => score.last_fetched_file_at != null)) {
      if (score.last_fetched_file_at != null
        && score.last_changed_at <= score.last_fetched_file_at) {
        continue;
      }

      const accessToken = await this._oidc.getActiveAccessToken();
      const musicxml = await this._api.getScoreMusicxml(score.id, accessToken);
      await this._storage.save(score.id, musicxml);
      score.last_fetched_file_at = new Date();
      await this._database.saveScore(score);
    }
  }

  /**
   * A score the way the API hands it over, as one this app keeps: the moments
   * as dates rather than as the strings they arrive as, and whatever is only
   * known locally carried over from the score being replaced.
   *
   * @param dto {import("./api.js").ScoreDto}
   * @returns {Score}
   * @private
   */
  _scoreFromApi(dto) {
    const existing = this._scores.get(dto.id);
    return new Score(
      dto.id,
      dto.work == null ? null : new Work(dto.work.title, dto.work.number),
      dto.movement == null ? null : new Movement(dto.movement.title, dto.movement.number),
      dto.creators == null ? null : new Creators(dto.creators.composers, dto.creators.lyricists),
      dto.languages,
      dto.instruments,
      dto.last_changed_at == null ? null : new Date(dto.last_changed_at),
      dto.tags,
      new Date(),
      existing?.last_fetched_file_at,
      existing?.last_viewed_at,
    );
  }

  /**
   * The score with the given id, asking the API for that one score when it is
   * not known here.
   *
   * A sync only ever asks for what changed since the last one, and the API
   * answers on when a score last changed rather than on when this app last
   * heard of it. So a score that is missing locally and was last changed before
   * the most recent sync is in no answer a sync will ever get: it has to be
   * asked for by its id, or it stays missing for good.
   *
   * `null` when there is no such score, or when nothing can be asked because
   * the API cannot be reached.
   *
   * @param scoreId {String}
   * @returns {Promise<Score|null>}
   * @private
   */
  async _ensureScore(scoreId) {
    const known = this._scores.get(scoreId);
    if (known != null) {
      return known;
    }

    if (!await this._api.canBeReached() || !await this._oidc.canBeReached()) {
      return null;
    }

    const accessToken = await this._oidc.getActiveAccessToken();
    const fromApi = await this._api.getScore(scoreId, accessToken);
    if (fromApi == null) {
      return null;
    }

    await this._addScoresFromApi([this._scoreFromApi(fromApi)]);
    return this._scores.get(scoreId) ?? null;
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
      const existing = this._scores.get(score.id);
      if (existing != null && existing.last_changed_at > score.last_changed_at) {
        continue;
      }
      toSave.push(score);
      this._scores.set(score.id, score);
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

    if (await this._storage.exists(scoreId)) {
      musicxml = await this._storage.get(scoreId);
    }
    if (musicxml != null) {
      await this._ensureScore(scoreId);
      return musicxml
    }

    if (!await this._api.canBeReached() || !await this._oidc.canBeReached()) {
      return null;
    }

    const accessToken = await this._oidc.getActiveAccessToken();
    musicxml = await this._api.getScoreMusicxml(scoreId, accessToken);
    if (musicxml == null) {
      alert('failed to load music xml');
      return null;
    }

    const score = await this._ensureScore(scoreId);
    if (score == null) {
      return musicxml;
    }
    score.last_fetched_file_at = new Date();
    await this._database.saveScore(score);
    await this._storage.save(scoreId, musicxml);
    return musicxml;
  }

  /**
   * Sets the `last_viewed_at` to "now" for the score with the given id. A score
   * that is not known here is asked for by id first; if there is no such score
   * at all, an error is thrown.
   *
   * @param scoreId {String}
   * @returns {Promise<void>}
   */
  async updateScoreLastViewedAt(scoreId) {
    const score = await this._ensureScore(scoreId);
    if (score == null) {
      throw new Error(`Score with id '${scoreId}' not found.`);
    }
    score.last_viewed_at = new Date();
    await this._database.saveScore(score);
    this._notifyScoresChangesListeners();
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

import {ApiConfig, ScoresApi} from "./domains/scores/api.js";
import {OidcApi, OidcConfig, OidcStorage, UserInfoResponse} from "./domains/auth/oidc-api.js";
import {ScoreDatabase} from "./domains/scores/database.js";
import {ScoresRepository} from "./domains/scores/repository.js";
import {SetsApi} from "./domains/sets/api.js";
import {SetDatabase} from "./domains/sets/database.js";
import {SetsRepository} from "./domains/sets/repository.js";
import {CollectionsApi} from "./domains/collections/api.js";
import {CollectionDatabase} from "./domains/collections/database.js";
import {CollectionsRepository} from "./domains/collections/repository.js";

const userInfoLocalStorageKey = 'app_user_info';

export class Config {
  /**
   * @param oidc {OidcConfig}
   * @param api {ApiConfig}
   */
  constructor(oidc, api) {
    this.oidc = oidc;
    this.api = api;
  }
}

export class App {
  /**
   * @param configPath {string}
   */
  constructor(configPath) {
    this.configPath = configPath;
  }

  /**
   * @type {ScoreDatabase}
   */
  scoreDatabase;
  /**
   * @type {OidcApi}
   */
  oidcApi;
  /**
   * @type {ScoresApi}
   */
  scoresApi;
  /**
   * @type {ScoresRepository}
   */
  scoreRepository;
  /**
   * @type {SetDatabase}
   */
  setDatabase;
  /**
   * @type {SetsApi}
   */
  setsApi;
  /**
   * @type {SetsRepository}
   */
  setRepository;
  /**
   * @type {CollectionDatabase}
   */
  collectionDatabase;
  /**
   * @type {CollectionsApi}
   */
  collectionsApi;
  /**
   * @type {CollectionsRepository}
   */
  collectionRepository;

  /**
   * @type {UserInfoResponse|null}
   */
  user;
  /**
   * Whether the user above is the copy this device kept, rather than what the
   * provider says right now. It is the difference between "these are your
   * roles" and "these were your roles the last time we could ask".
   *
   * @type {boolean}
   */
  userIsFromThisDevice = false;

  /**
   * @type {Config}
   */
  config;

  async initialize() {
    console.log('initializing app');
    await this.fetchConfig();
    this.scoreDatabase = new ScoreDatabase();
    this.setDatabase = new SetDatabase();
    this.collectionDatabase = new CollectionDatabase();
    this.oidcApi = new OidcApi(this.config.oidc);
    this.scoresApi = new ScoresApi(this.config.api);
    this.setsApi = new SetsApi(this.config.api);
    this.collectionsApi = new CollectionsApi(this.config.api);
    this.scoreRepository = new ScoresRepository(this.scoreDatabase, this.scoresApi, this.oidcApi);
    this.setRepository = new SetsRepository(this.setDatabase, this.setsApi, this.oidcApi);
    this.collectionRepository = new CollectionsRepository(
      this.collectionDatabase, this.collectionsApi, this.oidcApi);

    await this.updateAuth();
    await this.scoreDatabase.open();
    await this.setDatabase.open();
    await this.collectionDatabase.open();
    await this.scoreRepository.init();
    await this.setRepository.init();
    await this.collectionRepository.init();
    return this;
  }

  /**
   * Works out who is signed in on this device.
   *
   * **This never throws.** Whatever the provider does — cannot be reached, will
   * not take the token, answers something unreadable — the app still has to
   * start: the scores are on this device, they are drawn from this device, and
   * a player standing in front of a stand is not helped by a blank page saying
   * nothing. So every way of failing to ask ends in the same place as having no
   * network at all: the copy of the answer this device kept the last time it
   * could ask.
   *
   * What that costs is that the roles may be out of date, which the profile
   * page says out loud. What it buys is that the only thing an expired token
   * takes away is the API, which is the only thing it was ever proof of.
   *
   * @return {Promise<UserInfoResponse|null>}
   */
  async updateAuth() {
    if (!await this.oidcApi.canBeReached()) {
      return this._userKeptOnThisDevice();
    }

    try {
      this._accessToken = await this.oidcApi.getActiveAccessToken();
      if (this._accessToken == null) {
        // There was nothing to ask with, and the provider has been navigated to
        // so that there will be. Until that comes back, this device's own copy
        // is the best answer there is.
        return this._userKeptOnThisDevice();
      }

      this.user = await this.oidcApi.getUserInfo();
      this.userIsFromThisDevice = false;
      localStorage.setItem(userInfoLocalStorageKey, JSON.stringify(this.user));
      return this.user;
    } catch (error) {
      console.error('failed to ask the provider who is signed in', error);
      return this._userKeptOnThisDevice();
    }
  }

  /**
   * The answer this device kept the last time it could ask.
   *
   * Read back into a user rather than used as it comes out of the storage: what
   * JSON.parse hands over carries the fields but none of the methods, and every
   * question this app asks about a user — whether they may see a score, whether
   * they may upload one — is asked of a method. A plain object answers
   * `undefined` to all of them, which reads as a user with no roles at all.
   *
   * @return {UserInfoResponse|null}
   */
  _userKeptOnThisDevice() {
    const userJson = localStorage.getItem(userInfoLocalStorageKey);
    this.user = userJson == null ? null : UserInfoResponse.fromJson(JSON.parse(userJson));
    this.userIsFromThisDevice = true;
    return this.user;
  }

  /**
   * Forgets who is signed in on this device: the tokens they were proving it
   * with, and the copy of what the provider said about them.
   *
   * It signs nobody out at the provider — that is the provider's own business,
   * and this app is in no position to speak for it. What it does is make the
   * next visit ask again from the beginning, which is the way out of a token
   * or a set of roles that has gone stale.
   *
   * The scores, sets and collections on this device are left alone: they are
   * what makes the app work without a network, and they are no use to anyone
   * who cannot get a token to read them with anyway.
   */
  forgetUser() {
    localStorage.removeItem(userInfoLocalStorageKey);
    OidcStorage.tokenResponse = null;
    OidcStorage.refreshToken = null;
    OidcStorage.oidcFlowState = null;
    this.user = null;
  }

  async fetchConfig() {
    const response = await fetch(this.configPath);
    if (response.status >= 500) {
      throw `failed to fetch config (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to fetch config:  ${response.status} ${response.statusText}: ${await response.text()}`;
    }
    const json = await response.json();
    this.config = new Config(
      new OidcConfig(
        json.oidc.clientId,
        new URL(json.oidc.redirectUri),
        new URL(json.oidc.authorizationEndpoint),
        new URL(json.oidc.tokenEndpoint),
        new URL(json.oidc.userInfoEndpoint),
        new URL(json.oidc.healthzEndpoint),
        json.oidc.rolesKey
      ),
      new ApiConfig(
        new URL(json.api.baseUrl)
      ),
    )
  }

  async updateScores() {
    console.log('updating scores');
    if (!await this.scoresApi.canBeReached()) {
      return;
    }
    await this.scoreRepository.syncWithApi();
  }

  /**
   * Squares the sets with the API, which is also when whatever was written
   * while it could not be reached is sent.
   *
   * @return {Promise<void>}
   */
  async updateSets() {
    console.log('updating sets');
    if (!await this.setsApi.canBeReached() || !await this.oidcApi.canBeReached()) {
      return;
    }
    await this.setRepository.syncWithApi();
  }

  /**
   * Squares the collections with the API, which is also when whatever was
   * written while it could not be reached is sent.
   *
   * @return {Promise<void>}
   */
  async updateCollections() {
    console.log('updating collections');
    if (!await this.collectionsApi.canBeReached() || !await this.oidcApi.canBeReached()) {
      return;
    }
    await this.collectionRepository.syncWithApi();
  }
}

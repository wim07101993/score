import {ApiConfig, ScoresApi} from "./domains/scores/api.js";
import {OidcApi, OidcConfig, OidcStorage, UserInfoResponse} from "./domains/auth/oidc-api.js";
import {ScoreDatabase} from "./domains/scores/database.js";
import {ScoresRepository} from "./domains/scores/repository.js";
import {SetsApi} from "./domains/sets/api.js";
import {SetDatabase} from "./domains/sets/database.js";
import {SetsRepository} from "./domains/sets/repository.js";

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
    this.oidcApi = new OidcApi(this.config.oidc);
    this.scoresApi = new ScoresApi(this.config.api);
    this.setsApi = new SetsApi(this.config.api);
    this.scoreRepository = new ScoresRepository(this.scoreDatabase, this.scoresApi, this.oidcApi);
    this.setRepository = new SetsRepository(this.setDatabase, this.setsApi, this.oidcApi);

    await this.updateAuth();
    await this.scoreDatabase.open();
    await this.setDatabase.open();
    await this.scoreRepository.init();
    await this.setRepository.init();
    return this;
  }

  async updateAuth() {
    if (!await this.oidcApi.canBeReached()) {
      // Read back into a user rather than used as it comes out of the storage:
      // what JSON.parse hands over carries the fields but none of the methods,
      // and every question this app asks about a user — whether they may see a
      // score, whether they may upload one — is asked of a method. A plain
      // object answers `undefined` to all of them, which reads as a user with
      // no roles at all.
      const userJson = localStorage.getItem(userInfoLocalStorageKey);
      this.user = userJson == null ? null : UserInfoResponse.fromJson(JSON.parse(userJson));
      this.userIsFromThisDevice = true;
      return this.user;
    }

    this._accessToken = await this.oidcApi.getActiveAccessToken();
    if (this._accessToken == null) {
      this._accessToken = null;
      return null;
    }

    this.user = await this.oidcApi.getUserInfo()
    this.userIsFromThisDevice = false;
    const userJson = JSON.stringify(this.user);
    localStorage.setItem(userInfoLocalStorageKey, userJson);
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
   * The scores and sets on this device are left alone: they are what makes the
   * app work without a network, and they are no use to anyone who cannot get a
   * token to read them with anyway.
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
}

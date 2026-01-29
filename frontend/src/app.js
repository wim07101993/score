import {ApiConfig, ScoresApi} from "./domains/scores/api.js";
import {OidcApi, OidcConfig, UserInfoResponse} from "./domains/auth/oidc-api.js";
import {ScoreDatabase} from "./domains/scores/database.js";
import {ScoresRepository} from "./domains/scores/repository.js";

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
   * @type {UserInfoResponse|null}
   */
  user;

  /**
   * @type {Config}
   */
  config;

  async initialize() {
    console.log('initializing app');
    await this.fetchConfig();
    this.scoreDatabase = new ScoreDatabase();
    this.oidcApi = new OidcApi(this._config.oidc);
    this.scoresApi = new ScoresApi(this._config.api);
    this.scoreRepository = new ScoresRepository(this.scoreDatabase, this.scoresApi, this.oidcApi);

    await this.updateAuth();
    await this.scoreDatabase.open();
    await this.scoreRepository.init();
    return this;
  }

  async updateAuth() {
    if (!await this.oidcApi.canBeReached()) {
      const userJson = localStorage.getItem(userInfoLocalStorageKey);
      this.user = JSON.parse(userJson);
      return this.user;
    }

    this._accessToken = await this.oidcApi.getActiveAccessToken();
    if (this._accessToken == null) {
      this._accessToken = null;
      return null;
    }

    this.user = await this.oidcApi.getUserInfo()
    const userJson = JSON.stringify(this.user);
    localStorage.setItem(userInfoLocalStorageKey, userJson);
    return this.user;
  }

  async fetchConfig() {
    const response = await fetch(this.configPath);
    if (response.status >= 500) {
      throw `failed to fetch config (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to fetch config:  ${response.status} ${response.statusText}: ${await response.text()}`;
    }
    const json = await response.json();
    this._config = new Config(
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
}

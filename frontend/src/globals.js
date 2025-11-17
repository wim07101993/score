import {apiConfig, oidcConfig} from "./config.js";
import {ScoresApi} from "./data/scores-api.js";
import {Database} from "./data/database.js";
import {OidcService} from "./data/oidc.js";

const userInfoLocalStorageKey = 'app_user_info';

export const database = new Database();

export const oidcService = new OidcService(oidcConfig);

export const scoresApi = new ScoresApi(apiConfig);

/**
 * @type {UserInfoResponse}
 */
export let user;

/**
 * @type {String|null}
 */
export let accessToken = null;

export async function updateAuth() {
  if (!window.navigator.onLine) {
    const userJson = localStorage.getItem(userInfoLocalStorageKey);
    user = JSON.parse(userJson);
    return;
  }

  accessToken = await oidcService.authorize();
  if (accessToken == null) {
    accessToken = null;
    return null;
  }

  user = await oidcService.getUserInfo()
  const userJson = JSON.stringify(user);
  localStorage.setItem(userInfoLocalStorageKey, userJson);
}

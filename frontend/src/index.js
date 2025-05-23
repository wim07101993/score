import {authorizationCodeQueryParamName, authorize} from './auth/auth.js';
import {authConfig} from './auth/config.js';
import {getDatabase} from "./database/database.js";
import {startScoreFetchingBackgroundWorker} from "./score_fetcher/score_fetcher.js";

async function main() {
  const urlParams = new URLSearchParams(window.location.search);

  const accessToken = await authorize(
    authConfig.clientId,
    authConfig.redirectUri,
    authConfig.authorizationEndpoint,
    authConfig.tokenEndpoint,
    urlParams.get(authorizationCodeQueryParamName),
  );

  if (accessToken == null) {
    return;
  }

  // remove the authorization code from the url params
  window.history.replaceState(null, null, window.location.pathname);

  await getDatabase();

  if (window.Worker) {
    startScoreFetchingBackgroundWorker();
  } else {
    alert("background workers are not supported, application won't work...");
  }
}

await main();

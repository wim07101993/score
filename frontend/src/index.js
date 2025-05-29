import {authorizationCodeQueryParamName, authorize} from './data/auth/auth.js';
import {authConfig} from './data/auth/config.js';
import {getDatabase} from "./data/database/database.js";
import {startScoreFetchingBackgroundWorker} from "./data/score-fetcher/score_fetcher.js";

import {registerScoreList} from "./components/score-list/score-list.component.js";
import {registerScoreListItem} from "./components/score-list-item/score-list-item.component.js";
import {registerScoreListPage} from "./components/pages/score-list-page.component.js";

console.log('index.js');

async function main() {
  await Promise.all([
    registerScoreList(),
    registerScoreListItem(),
    registerScoreListPage(),
  ])
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

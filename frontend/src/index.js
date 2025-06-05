import {authorizationCodeQueryParamName, authorize} from './data/auth/auth.js';
import {authConfig} from './data/auth/config.js';
import {getDatabase} from "./data/database/database.js";
import {startScoreFetchingBackgroundWorker} from "./data/score-fetcher/score_fetcher.js";

import {registerScoreList} from "./components/score-list.component.js";
import {registerScoreListItem} from "./components/score-list-item.component.js";
import {registerScoreListPage} from "./components/pages/score-list-page.component.js";
import {loadPage} from "./router.js";

console.log('index.js');
console.log(window.location.hash);
let currentPage = '/'

async function main() {
  registerScoreList();
  registerScoreListItem();
  registerScoreListPage();

  if (currentPage !== window.location.hash) {
    // don't know why but without the string conversion, the page load fails
    const route = window.location.hash + '';
    document.getElementById('app').innerHTML = loadPage(route);
    currentPage = window.location.hash;
  }


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
  console.log('user is logged in');

  // remove the authorization code from the url params
  // window.history.replaceState(null, null, window.location.pathname);

  await getDatabase();

  if (window.Worker) {
    startScoreFetchingBackgroundWorker();
  } else {
    alert("background workers are not supported, application won't work...");
  }
}

await main();

import {authorizationCodeQueryParamName, authorize} from './data/auth/auth.js';
import {authConfig} from './data/auth/config.js';

import {registerScoreList} from "./components/score-list.component.js";
import {registerScoreListItem} from "./components/score-list-item.component.js";
import {registerScoreListPage} from "./components/pages/score-list-page.component.js";
import {loadPage} from "./router.js";
import {registerScoreDetailPage} from "./components/pages/score-detail-page.component.js";
import {registerScoreDetail} from "./components/score-detail.component.js";
import {appState} from "./app-state.js";

let currentPage = '/'

async function main() {
  registerScoreList();
  registerScoreListItem();
  registerScoreDetail();
  registerScoreListPage();
  registerScoreDetailPage();

  appState.initialization
    .then((appState) => appState.api.getScores(new Date(2000), new Date()))
    .then((scores) => appState.database.addScores(scores))

  onhashchange = () => updatePage();
  updatePage();

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
}

function updatePage() {
  console.log('updating page');
  if (currentPage === window.location.hash) {
    return;
  }
  // don't know why but without the string conversion, the page load fails
  const route = window.location.hash + '';
  document.getElementById('app').innerHTML = loadPage(route);
  currentPage = window.location.hash;
}

await main();

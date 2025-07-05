import {authorize} from './data/auth/auth.js';

import {buildScoreListItem, registerScoreListItem} from "./components/score-list-item.component.js";
import {appState} from "./app-state.js";

async function main() {
  registerScoreListItem();

  appState.initialization
    .then((appState) => appState.api.getScores(new Date(2000), new Date()))
    .then((scores) => appState.database.addScores(scores))

  const accessToken = await authorize();
  if (accessToken == null) {
    return;
  }


  appState.database.addScoreChangesListener(() => _buildScoreListItems());
  _buildScoreListItems().then(() => console.log('built score list items'));
}

async function _buildScoreListItems() {
  const container = document.getElementById('score-list');
  await appState.initialization;
  for (const score of appState.database.scores) {
    const listItem = buildScoreListItem(score);
    container.appendChild(listItem);
  }
}

await main();

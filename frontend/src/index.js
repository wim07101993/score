import {authorize} from './data/auth/auth.js';

import {buildScoreListItem, registerScoreListItem} from "./components/score-list-item.component.js";
import {appState} from "./app-state.js";

async function main() {
  registerScoreListItem();

  const accessToken = await authorize();
  if (accessToken == null) {
    return;
  }

  await appState.initialization;

  appState.database.addScoreChangesListener(() => _buildScoreListItems());

  appState.fetchScoreUpdates().then(() => {});
  _buildScoreListItems().then(() => {});
}

async function _buildScoreListItems() {
  const container = document.getElementById('score-list');
  container.innerHTML = '';
  await appState.initialization;
  for (const score of appState.database.scores) {
    const listItem = buildScoreListItem(score);
    container.appendChild(listItem);
  }
}

await main();

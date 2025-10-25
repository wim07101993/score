import {buildScoreListItem, registerScoreListItem} from "./components/score-list-item.component.js";
import {fetchScoreUpdates, initializeScoreApp} from "./score-domain.js";
import {authService, database} from "./globals.js";

async function main() {
  registerScoreListItem();

  const accessToken = await authService.authorize();
  if (accessToken == null) {
    return;
  }

  const userInfo = await authService.getUserInfo();
  document.getElementById('upload-button').hidden = userInfo == null
    || userInfo.roles == null
    || userInfo.roles['score_viewer'] == null;

  await initializeScoreApp();

  database.addScoreChangesListener(() => _buildScoreListItems());

  fetchScoreUpdates().then(() => {
  });
  _buildScoreListItems().then(() => {
  });
}

async function _buildScoreListItems() {
  const container = document.getElementById('score-list');
  container.innerHTML = '';
  await initializeScoreApp();
  for (const score of database.scores) {
    const listItem = buildScoreListItem(score);
    container.appendChild(listItem);
  }
}

await main();

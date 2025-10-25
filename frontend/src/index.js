import {buildScoreListItem, registerScoreListItem} from "./components/score-list-item.component.js";
import {fetchScoreUpdates, initializeScoreApp} from "./score-domain.js";
import {authService, database} from "./globals.js";

async function main() {
  registerScoreListItem();

  const accessToken = await authService.authorize();
  if (accessToken == null) {
    return;
  }

  const user = await authService.getUserInfo();

  await initializeScoreApp();

  database.addScoreChangesListener(() => _buildScoreListItems());


  if (user?.isScoreEditor === true){
    document.getElementById('upload-button').hidden = false;
  } else {
    document.getElementById('upload-button').hidden = true;
    console.log('not score editor');
  }

  if (user?.isScoreViewer === true) {
    document.getElementById('score-list').hidden = false;
    fetchScoreUpdates().then(() => {
    });
    _buildScoreListItems().then(() => {
    });
  } else {
    document.getElementById('score-list').hidden = true;
    console.log('not score viewer');
  }
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

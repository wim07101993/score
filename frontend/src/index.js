import {buildScoreListItem, registerScoreListItem} from "./components/score-list-item.component.js";
import {fetchScoreUpdates, initializeScoreApp} from "./score-domain.js";
import {database, updateAuth, user} from "./globals.js";

const uploadButton = document.getElementById('upload-button');
const scoreList = document.getElementById('score-list');

async function _buildScoreListItems() {
  scoreList.innerHTML = '';
  await initializeScoreApp();
  for (const score of database.scores) {
    const listItem = buildScoreListItem(score);
    scoreList.appendChild(listItem);
  }
}

async function main() {
  registerScoreListItem();

  await updateAuth();

  await initializeScoreApp();

  database.addScoreChangesListener(() => _buildScoreListItems());

  if (user?.isScoreEditor === true) {
    uploadButton.hidden = false;
  } else {
    uploadButton.hidden = true;
    console.log('not score editor');
  }

  if (user?.isScoreViewer === true) {
    scoreList.hidden = false;
    fetchScoreUpdates().then(() => {
    });
    _buildScoreListItems().then(() => {
    });
  } else {
    scoreList.hidden = true;
    console.log('not score viewer');
  }
}

await main();

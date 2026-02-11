import {buildScoreListItem, registerScoreListItem} from "./components/score-list-item.component.js";
import {App} from "./app.js";

const uploadButton = document.getElementById('upload-button');
const scoreList = document.getElementById('score-list');

const app = new App('config.json');

function _buildScoreListItems() {
  scoreList.innerHTML = '';
  const sortedScores = app.scoreRepository.scores.sort((a, b) => b.last_viewed_at - a.last_viewed_at);
  for (const score of sortedScores) {
    const listItem = buildScoreListItem(score);
    scoreList.appendChild(listItem);
  }
}

function _initScoreEditor() {
  if (app.user?.isScoreEditor !== true) {
    uploadButton.hidden = true;
    console.log('no score editor');
    return
  }

  uploadButton.hidden = false;
}

async function _initScoreViewer() {
  if (app.user?.isScoreViewer !== true) {
    scoreList.hidden = true;
    console.log('no score viewer');
    return;
  }

  scoreList.hidden = false;
  _buildScoreListItems();
  await app.updateScores();
}

async function main() {
  registerScoreListItem();

  await app.initialize();

  app.scoreRepository.addScoreChangesListener(() => _buildScoreListItems());

  _initScoreEditor();
  await _initScoreViewer();
}

await main();

import {buildScoreCard} from "./components/score-card.component.js";
import {App} from "./app.js";

const uploadButton = document.getElementById('upload-button');
const setsButton = document.getElementById('sets-button');
const scoreList = document.getElementById('score-list');
const emptyNotice = document.getElementById('empty-notice');

const app = new App('config.json');

function _buildScoreListItems() {
  scoreList.replaceChildren();
  const sortedScores = app.scoreRepository.scores.sort((a, b) => (b.last_viewed_at ?? 0) - (a.last_viewed_at ?? 0));
  for (const score of sortedScores) {
    scoreList.appendChild(buildScoreCard(score));
  }
  emptyNotice.hidden = sortedScores.length > 0;
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
    setsButton.hidden = true;
    emptyNotice.hidden = true;
    console.log('no score viewer');
    return;
  }

  // A set names scores but changes nothing about them, so keeping one asks no
  // more of a user than reading the scores in it.
  setsButton.hidden = false;
  scoreList.hidden = false;
  _buildScoreListItems();
  await app.updateScores();
}

async function main() {
  await app.initialize();

  app.scoreRepository.addScoreChangesListener(() => _buildScoreListItems());

  _initScoreEditor();
  await _initScoreViewer();

  // Whatever was written to a set while there was nothing to send it to is
  // still owed to the server, and any page with a network is a chance to send
  // it: waiting for the player to open the sets again is waiting for nothing.
  if (app.user?.isScoreViewer === true) {
    try {
      await app.updateSets();
    } catch (error) {
      console.error('failed to sync the sets', error);
    }
  }
}

await main();

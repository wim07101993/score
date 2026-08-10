import {App} from "../app.js";
import {buildSetListItem, registerSetListItem} from "../components/set-list-item.component.js";

const newSetButton = document.getElementById('new-set-button');
const setList = document.getElementById('set-list');
const emptyNotice = document.getElementById('empty-notice');
const offlineNotice = document.getElementById('offline-notice');

const app = new App('../config.json');

function _buildSetListItems() {
  setList.replaceChildren();
  const sets = app.setRepository.sets;
  for (const set of sets) {
    setList.appendChild(buildSetListItem(set));
  }
  emptyNotice.hidden = sets.length > 0;
}

async function main() {
  registerSetListItem();

  await app.initialize();

  if (app.user?.isScoreViewer !== true) {
    setList.hidden = true;
    emptyNotice.hidden = true;
    console.log('no score viewer');
    return;
  }

  newSetButton.hidden = false;
  app.setRepository.addSetsChangesListener(() => _buildSetListItems());
  _buildSetListItems();

  // What is on screen is what this device has, whether or not there is anything
  // to sync with; syncing only ever adds to it.
  try {
    await app.updateSets();
  } catch (error) {
    console.error('failed to sync the sets', error);
    offlineNotice.hidden = false;
  }

  // The scores are what a set is built out of, so a set that was written on
  // another device is only readable here once its scores are.
  try {
    await app.updateScores();
  } catch (error) {
    console.error('failed to sync the scores', error);
  }
}

await main();

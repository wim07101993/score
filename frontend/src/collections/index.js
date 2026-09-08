import {App} from "../app.js";
import {buildCollectionCard} from "../components/collection-card.component.js";
import {keepAppUpToDate} from "../domains/updates/app-update.js";

const newCollectionButton = document.getElementById('new-collection-button');
const collectionList = document.getElementById('collection-list');
const emptyNotice = document.getElementById('empty-notice');
const offlineNotice = document.getElementById('offline-notice');

const app = new App('../config.json');

function _buildCollectionListItems() {
  collectionList.replaceChildren();
  const collections = app.collectionRepository.collections;
  for (const collection of collections) {
    collectionList.appendChild(buildCollectionCard(collection));
  }
  emptyNotice.hidden = collections.length > 0;
}

async function main() {
  // A listing holds nothing the reader has half-written, so being handed a
  // newer app costs them nothing here.
  keepAppUpToDate({reloadWhenReplaced: true})
    .catch((error) => console.error('failed to watch for a newer app', error));

  await app.initialize();

  if (app.user?.isScoreViewer !== true) {
    collectionList.hidden = true;
    emptyNotice.hidden = true;
    console.log('no score viewer');
    return;
  }

  newCollectionButton.hidden = false;
  app.collectionRepository.addCollectionsChangesListener(() => _buildCollectionListItems());
  _buildCollectionListItems();

  // What is on screen is what this device has, whether or not there is anything
  // to sync with; syncing only ever adds to it.
  try {
    await app.updateCollections();
  } catch (error) {
    console.error('failed to sync the collections', error);
    offlineNotice.hidden = false;
  }

  // The scores are what a collection is made of, so one that was written on
  // another device is only readable here once its scores are.
  try {
    await app.updateScores();
  } catch (error) {
    console.error('failed to sync the scores', error);
  }
}

await main();

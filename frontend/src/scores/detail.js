import {authorize} from '../data/auth/auth.js';
import {getMusicxml, musicxmlExists, saveMusicxml} from '../data/database/storage.js';

import {appState} from "../app-state.js";

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");

/**
 * @param scoreId {String}
 * @returns {Promise<void>}
 */
async function loadMusicxml(scoreId) {
  let musicxml = null;

  if (musicxmlExists(scoreId)) {
    musicxml = await getMusicxml(scoreId)
  } else {
    const accessToken = await authorize();
    if (accessToken == null) {
      return;
    }

    musicxml = await appState.api.getScoreMusicxml(scoreId, accessToken);
    await saveMusicxml(scoreId, musicxml);
  }

  if (musicxml == null) {
    // TODO show user something
    return;
  }

  await osmd.load(musicxml)
    .then(() => osmd.render());
}

async function main() {
  const accessToken = await authorize();
  if (accessToken == null) {
    return;
  }

  const urlParams = new URLSearchParams(window.location.search);
  const scoreId = urlParams.get('id');
  if (scoreId == null) {
    return;
  }

  await appState.initialization;
  appState.fetchScoreUpdates().then(() => loadMusicxml(scoreId));

  await loadMusicxml(scoreId);
}

await main();

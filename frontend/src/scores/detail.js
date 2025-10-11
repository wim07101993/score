import {getMusicxml, musicxmlExists, saveMusicxml} from '../data/storage.js';

import {api, authService} from "../globals";
import {fetchScoreUpdates, initializeScoreApp} from "../score-domain.js";

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
    const accessToken = await authService.authorize();
    if (accessToken == null) {
      return;
    }

    musicxml = await api.getScoreMusicxml(scoreId, accessToken);
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
  const accessToken = await authService.authorize();
  if (accessToken == null) {
    return;
  }

  const urlParams = new URLSearchParams(window.location.search);
  const scoreId = urlParams.get('id');
  if (scoreId == null) {
    return;
  }

  await initializeScoreApp();
  fetchScoreUpdates().then(() => loadMusicxml(scoreId));

  await loadMusicxml(scoreId);
}

await main();

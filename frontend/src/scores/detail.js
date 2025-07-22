import {authorize} from '../data/auth/auth.js';

import {appState} from "../app-state.js";

async function main() {

  const accessToken = await authorize();
  if (accessToken == null) {
    return;
  }

  await appState.initialization;

  const urlParams = new URLSearchParams(window.location.search);
  const scoreId = urlParams.get('id');
  if (scoreId == null) {
    return;
  }

  const musicxml = await appState.api.getScoreMusicxml(scoreId, accessToken);

  const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");
  osmd.load(musicxml)
    .then(() => osmd.render())
    .then(() => 'rendered');
}

await main();

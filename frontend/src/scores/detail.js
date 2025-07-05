import {authorize} from '../data/auth/auth.js';

import {appState} from "../app-state.js";

async function main() {

  appState.initialization
    .then((appState) => appState.api.getScores(new Date(2000), new Date()))
    .then((scores) => appState.database.addScores(scores))

  const accessToken = await authorize();
  if (accessToken == null) {
    return;
  }


}

await main();

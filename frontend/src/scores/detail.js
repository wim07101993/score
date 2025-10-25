import {getMusicxml, musicxmlExists, saveMusicxml} from '../data/storage.js';

import {api, authService} from "../globals.js";
import {fetchScoreUpdates, initializeScoreApp} from "../score-domain.js";

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");

const fileInput = document.getElementById('file-input');
const uploadForm = document.getElementById('upload-form');
const uploadButton = document.getElementById('upload-button');

/**
 * @type {string}
 */
let musicXml;
let scoreId;
let accessToken;

/**
 * @param scoreId {String}
 * @returns {Promise<void>}
 */
async function loadMusicxml(scoreId) {
  let musicxml = null;

  if (await musicxmlExists(scoreId)) {
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
    alert('failed to load music xml');
    return;
  }

  await osmd.load(musicxml)
    .then(() => osmd.render());
}

/**
 * @param event {Event}
 * @return {Promise<void>}
 */
async function onFileSelected(event) {
  console.log('selected file');
  if (event.target.files.length === 0) {
    uploadButton.disabled = true;
    osmd.clear();
    console.log('no files');
    return;
  }

  const file = event.target.files[0];

  if (!file.name.match('.*\.musicxml')) {
    uploadButton.disabled = true;
    alert('You selected a non-xml file. Please select only music xml files.');
    return;
  }

  uploadButton.disabled = false;
  const reader = new FileReader();
  reader.onload = function (e) {
    musicXml = e.target.result;
    osmd.load(musicXml)
      .then(() => osmd.render());
  };
  reader.readAsText(file);
}

/**
 * @param event {Event}
 */
async function onSubmitScore(event) {
  event.preventDefault();
  await api.putScore(scoreId, accessToken, musicXml);
  window.location = `detail.html?id=${scoreId}`;
}

async function main() {
  accessToken = await authService.authorize();
  if (accessToken == null) {
    alert('you are not logged in');
    return;
  }

  fileInput.addEventListener('change', onFileSelected);
  uploadForm.addEventListener('submit', onSubmitScore);

  const urlParams = new URLSearchParams(window.location.search);
  scoreId = urlParams.get('id');
  if (scoreId == null) {
    scoreId = crypto.randomUUID()
    return;
  }

  await initializeScoreApp();
  fetchScoreUpdates().then(() => loadMusicxml(scoreId));

  await loadMusicxml(scoreId);
}

await main();

import {getMusicxml, musicxmlExists, saveMusicxml} from '../data/storage.js';

import {accessToken, scoresApi, updateAuth, user} from "../globals.js";
import {fetchScoreUpdates, initializeScoreApp} from "../score-domain.js";

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");

const fileInput = document.getElementById('file-input');
const uploadForm = document.getElementById('upload-form');
const uploadButton = document.getElementById('upload-button');
const downloadButton = document.getElementById('download-button');
const scoreMusicXml = document.getElementById('score-musicxml');

/**
 * @type {string|null}
 */
let musicXml;
let scoreId;

/**
 * @param scoreId {String}
 */
async function loadMusicxml(scoreId) {
  let musicxml;

  if (await musicxmlExists(scoreId)) {
    musicxml = await getMusicxml(scoreId)
  } else {
    await updateAuth();

    musicxml = await scoresApi.getScoreMusicxml(scoreId, accessToken);
    await saveMusicxml(scoreId, musicxml);
  }

  if (musicxml == null) {
    alert('failed to load music xml');
  }
  return musicxml;
}

/**
 * @param event {Event}
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
async function onUploadFormSubmit(event) {
  event.preventDefault();
  await scoresApi.putScore(scoreId, accessToken, musicXml);
  window.location = `detail.html?id=${scoreId}`;
}

function onDownloadButtonClicked() {
  const blob = new Blob([musicXml], {type: 'application/vnd.recordare.musicxml'});
  const url = window.URL.createObjectURL(blob);

  const link = document.createElement('a');
  link.href = url;
  link.download = `${scoreId}.musicxml`;
  document.body.appendChild(link);
  link.click();

  // Clean up
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
}

async function main() {
  await updateAuth();

  fileInput.addEventListener('change', onFileSelected);
  uploadForm.addEventListener('submit', onUploadFormSubmit);
  downloadButton.addEventListener('click', onDownloadButtonClicked);

  if (user?.isScoreEditor === true) {
    uploadForm.hidden = false;
  } else {
    uploadForm.hidden = true;
    console.log('not score editor');
  }

  if (user?.isScoreViewer === true) {
    scoreMusicXml.hidden = false;
    downloadButton.hidden = false;
  } else {
    scoreMusicXml.hidden = true;
    downloadButton.hidden = true;
    console.log('not score viewer');
  }

  const urlParams = new URLSearchParams(window.location.search);
  scoreId = urlParams.get('id');
  if (scoreId == null) {
    scoreId = crypto.randomUUID()
  }

  await initializeScoreApp();
  fetchScoreUpdates().then(() => loadMusicxml(scoreId));

  musicXml = await loadMusicxml(scoreId);

  await osmd.load(musicXml)
    .then(() => osmd.render());
}

await main();

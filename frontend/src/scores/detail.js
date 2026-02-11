import {App} from "../app.js";

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");

const fileInput = document.getElementById('file-input');
const uploadForm = document.getElementById('upload-form');
const uploadButton = document.getElementById('upload-button');
const downloadButton = document.getElementById('download-button');
const scoreMusicXml = document.getElementById('score-musicxml');

const app = new App('../config.json');

/**
 * @type {string|null}
 */
let musicXml;
let scoreId;

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
  const user = await app.updateAuth();
  if (await user?.isScoreEditor !== true) {
    return;
  }
  const accessToken = await app.oidcApi.getActiveAccessToken();
  if (scoreId == null) {
    scoreId = crypto.randomUUID();
  }
  await app.scoresApi.putScore(scoreId, accessToken, musicXml);
  window.location = `detail.html?id=${scoreId}`;
}

async function onDownloadButtonClicked() {
  const user = await app.updateAuth();
  if (await user?.isScoreViewer !== true) {
    return;
  }

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

function _initScoreEditor() {
  if (app.user?.isScoreViewer !== true) {
    fileInput.hidden = true;
    uploadButton.hidden = true;
    uploadForm.hidden = true;
    console.log('no score editor');
    return;
  }

  fileInput.hidden = false;
  uploadButton.hidden = false;
  uploadForm.hidden = false;
}

async function _initScoreViewer() {
  if (app.user?.isScoreViewer !== true) {
    downloadButton.hidden = true;
    scoreMusicXml.hidden = true;
    console.log('no score viewer');
    return;
  }

  downloadButton.hidden = false;
  scoreMusicXml.hidden = false;

  if (scoreId != null) {
    musicXml = await app.scoreRepository.getMusicXml(scoreId);
    if (musicXml != null) {
      await osmd.load(musicXml).then(() => osmd.render());
    }
    try {
      await app.scoreRepository.updateScoreLastViewedAt(scoreId);
    } catch (error) {
      console.error('Failed to update score last viewed timestamp for scoreId:', scoreId, error);
    }
  }

  await app.updateScores();
}

async function main() {
  await app.initialize();

  fileInput.addEventListener('change', onFileSelected);
  uploadForm.addEventListener('submit', onUploadFormSubmit);
  downloadButton.addEventListener('click', onDownloadButtonClicked);

  const urlParams = new URLSearchParams(window.location.search);
  scoreId = urlParams.get('id');
  _initScoreEditor();
  await _initScoreViewer();
}

await main();

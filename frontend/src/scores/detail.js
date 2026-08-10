import {App} from "../app.js";
import {ScoreRenderer} from "../domains/scores/osmd-score-view.js";
import {musicXmlForView} from "../domains/scores/musicxml-view.js";

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");
const renderer = new ScoreRenderer(osmd);

const fileInput = document.getElementById('file-input');
const uploadForm = document.getElementById('upload-form');
const uploadButton = document.getElementById('upload-button');
const downloadMenu = document.getElementById('download-menu');
const downloadSvgButton = document.getElementById('download-svg-button');
const downloadMusicXmlButton = document.getElementById('download-musicxml-button');
const scoreMusicXml = document.getElementById('score-musicxml');

const viewControls = document.getElementById('score-view-controls');
const transpositionInput = document.getElementById('transposition-input');
const transpositionOutput = document.getElementById('transposition-output');
const partsList = document.getElementById('parts-list');
const resetViewButton = document.getElementById('reset-view-button');

const app = new App('../config.json');

/**
 * The music-xml of the score as it was uploaded. Hiding parts and transposing
 * never touch it: they are applied to what OSMD draws, so this stays the
 * document that is downloaded and re-uploaded.
 *
 * @type {string|null}
 */
let musicXml;
let scoreId;

/**
 * How the score is currently being looked at. Never stored, and gone as soon as
 * the page is left.
 *
 * @type {import("../domains/scores/score-view.js").ScoreView|null}
 */
let scoreView = null;

/**
 * @type {import("../domains/scores/osmd-score-view.js").ScorePart[]}
 */
let scoreParts = [];

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
    _showScore(musicXml).catch((error) => console.error('failed to show the score', error));
  };
  reader.readAsText(file);
}

// ----------------------------------------------------------------------------
// SHOWING A SCORE
// ----------------------------------------------------------------------------

/**
 * Draws a score and starts it off being looked at the way it was written.
 *
 * @param xml {string}
 */
async function _showScore(xml) {
  scoreView = await renderer.load(xml);
  scoreParts = renderer.parts;

  _drawPartControls();
  _syncViewControls();
  viewControls.hidden = scoreParts.length === 0;

  _syncScoreOffset();
}

/**
 * Changing the transposition reads the score again, so a change can still be
 * running when the next one is asked for. They are queued rather than run over
 * one another, and each one is handed the view as it is by the time its turn
 * comes rather than as it was when it was clicked.
 *
 * @type {Promise<void>}
 */
let pendingViewChange = Promise.resolve();

/**
 * @param change {function(import("../domains/scores/score-view.js").ScoreView):
 *   import("../domains/scores/score-view.js").ScoreView}
 */
function _queueViewChange(change) {
  pendingViewChange = pendingViewChange
    .then(() => _changeView(scoreView == null ? null : change(scoreView)))
    .catch((error) => console.error('failed to change the view of the score', error));
}

/**
 * Looks at the score a different way. The score is not touched; only what is
 * drawn from it is.
 *
 * @param next {import("../domains/scores/score-view.js").ScoreView|null}
 */
async function _changeView(next) {
  if (scoreView == null || next == null || next === scoreView) {
    // A view hands itself back when it refuses a change, such as hiding the
    // last part left. The controls are drawn from the view, so redrawing them
    // puts the refused control back the way it was.
    _syncViewControls();
    return;
  }

  scoreView = next;
  await renderer.apply(scoreView);
  _syncViewControls();
  _syncScoreOffset();
}

/** Builds a checkbox per part of the score that is loaded. */
function _drawPartControls() {
  partsList.replaceChildren();

  for (const part of scoreParts) {
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.id = `part-${part.id}`;
    checkbox.checked = true;
    checkbox.addEventListener('change', () =>
      _queueViewChange((view) => view.withPartVisible(part.id, checkbox.checked)));

    const label = document.createElement('label');
    label.htmlFor = checkbox.id;
    label.append(checkbox, document.createTextNode(` ${part.name}`));

    partsList.append(label);
  }
}

/**
 * Says what the two downloads would hand over right now.
 *
 * A score nobody has changed the look of is written out as the file it was
 * uploaded as, so there is no point in the menu claiming otherwise; once
 * something has been transposed or taken off the screen, it says so.
 */
function _syncDownloadMenu() {
  const asViewed = scoreView != null && !scoreView.isPristine;
  downloadMusicXmlButton.textContent = asViewed
    ? 'Score file, as on screen (.musicxml)'
    : 'Score file, as written (.musicxml)';
  downloadSvgButton.disabled = scoreView == null;
}

/** Puts the controls back in step with the view they are controlling. */
function _syncViewControls() {
  _syncDownloadMenu();

  if (scoreView == null) {
    return;
  }

  transpositionInput.value = `${scoreView.transposition}`;
  _showTransposition();

  for (const part of scoreParts) {
    const checkbox = document.getElementById(`part-${part.id}`);
    if (checkbox != null) {
      checkbox.checked = !scoreView.isHidden(part.id);
    }
  }

  resetViewButton.disabled = scoreView.isPristine;
}

/** Writes the number on the transposition control, signed so up reads as up. */
function _showTransposition() {
  const semitones = Number(transpositionInput.value);
  transpositionOutput.textContent = semitones > 0 ? `+${semitones}` : `${semitones}`;
}

/**
 * The header is fixed, so the score has to start below it. Opening the controls
 * makes the header taller, which is why this is not a constant.
 */
function _syncScoreOffset() {
  const header = document.querySelector('header');
  if (header != null) {
    scoreMusicXml.style.paddingTop = `${header.offsetHeight}px`;
  }
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

// ----------------------------------------------------------------------------
// TAKING A SCORE AWAY
// ----------------------------------------------------------------------------

/**
 * Both of these are the score as it is being looked at rather than as it was
 * uploaded: the parts that are off screen are not in either of them, and both
 * are in the key it is being read in. A score nobody has touched comes out as
 * the file the editor uploaded, which is what it was before there was anything
 * to touch.
 */

async function onDownloadSvgClicked() {
  downloadMenu.open = false;
  if (!await _mayDownload()) {
    return;
  }

  const svg = renderer.toSvg();
  if (svg == null) {
    alert('There is nothing on screen to take a copy of yet.');
    return;
  }
  _download(new Blob([svg], {type: 'image/svg+xml'}), `${scoreId}.svg`);
}

async function onDownloadMusicXmlClicked() {
  downloadMenu.open = false;
  if (!await _mayDownload()) {
    return;
  }

  let written;
  try {
    written = musicXmlForView(musicXml, scoreView);
  } catch (error) {
    console.error('failed to write the score out the way it is being looked at', error);
    alert(`This score could not be written out: ${error.message ?? error}`);
    return;
  }
  _download(
    new Blob([written], {type: 'application/vnd.recordare.musicxml'}),
    `${scoreId}.musicxml`);
}

/** @return {Promise<boolean>} */
async function _mayDownload() {
  if (scoreId == null || musicXml == null) {
    alert('This score cannot be downloaded because it has not been loaded or saved yet.');
    return false;
  }
  const user = await app.updateAuth();
  return await user?.isScoreViewer === true;
}

/**
 * @param blob {Blob}
 * @param filename {string}
 */
function _download(blob, filename) {
  const url = window.URL.createObjectURL(blob);

  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
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
    downloadMenu.hidden = true;
    scoreMusicXml.hidden = true;
    viewControls.hidden = true;
    console.log('no score viewer');
    return;
  }

  downloadMenu.hidden = false;
  scoreMusicXml.hidden = false;

  if (scoreId != null) {
    musicXml = await app.scoreRepository.getMusicXml(scoreId);
    if (musicXml != null) {
      await _showScore(musicXml);
      try {
        await app.scoreRepository.updateScoreLastViewedAt(scoreId);
      } catch (error) {
        console.error('Failed to update score last viewed timestamp for scoreId:', scoreId, error);
      }
    }
  }

  await app.updateScores();
}

async function main() {
  await app.initialize();

  fileInput.addEventListener('change', onFileSelected);
  uploadForm.addEventListener('submit', onUploadFormSubmit);
  downloadSvgButton.addEventListener('click', onDownloadSvgClicked);
  downloadMusicXmlButton.addEventListener('click', onDownloadMusicXmlClicked);
  _syncDownloadMenu();

  // A menu that is left open over the score once it has been finished with is
  // in the way, and clicking off it is how a menu is put away.
  document.addEventListener('click', (event) => {
    if (!downloadMenu.contains(event.target)) {
      downloadMenu.open = false;
    }
  });

  // Redrawing a score is expensive enough that doing it for every pixel of a
  // drag is not worth it, so dragging only moves the number and letting go
  // redraws.
  transpositionInput.addEventListener('input', _showTransposition);
  transpositionInput.addEventListener('change', () =>
    _queueViewChange((view) => view.withTransposition(Number(transpositionInput.value))));
  resetViewButton.addEventListener('click', () => _queueViewChange((view) => view.reset()));
  viewControls.addEventListener('toggle', _syncScoreOffset);
  window.addEventListener('resize', _syncScoreOffset);

  const urlParams = new URLSearchParams(window.location.search);
  scoreId = urlParams.get('id');
  _initScoreEditor();
  await _initScoreViewer();
}

await main();

import {App} from "../app.js";
import {ScoreRenderer} from "../domains/scores/osmd-score-view.js";
import {MAX_TRANSPOSITION, MIN_TRANSPOSITION} from "../domains/scores/score-view.js";

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");
const renderer = new ScoreRenderer(osmd);

const fileInput = document.getElementById('file-input');
const uploadForm = document.getElementById('upload-form');
const uploadButton = document.getElementById('upload-button');
const downloadButton = document.getElementById('download-button');
const scoreMusicXml = document.getElementById('score-musicxml');

const viewControls = document.getElementById('score-view-controls');
const transpositionInput = document.getElementById('transposition-input');
const transpositionOutput = document.getElementById('transposition-output');
const partsList = document.getElementById('parts-list');
const resetViewButton = document.getElementById('reset-view-button');

const setControls = document.getElementById('set-controls');
const setButton = document.getElementById('set-button');
const setPosition = document.getElementById('set-position');
const setPreviousButton = document.getElementById('set-previous-button');
const setNextButton = document.getElementById('set-next-button');
const setEntryDescription = document.getElementById('set-entry-description');
const saveViewToSetButton = document.getElementById('save-view-to-set-button');

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
 * The set this score is being played from, when it is being played from one:
 * which set it is, and which of its entries this is.
 *
 * An entry is pointed at by where it comes in the set rather than by its id.
 * The server mints those again on every write — an entry names an entry of the
 * set as it reads now and nothing beyond that — and what stays put across a
 * write is the order.
 *
 * @type {{set: import("../domains/sets/database.js").ScoreSet, index: number,
 *   entry: import("../domains/sets/database.js").SetEntry}|null}
 */
let setContext = null;

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

/** Puts the controls back in step with the view they are controlling. */
function _syncViewControls() {
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
  _syncSetControls();
}

// ----------------------------------------------------------------------------
// PLAYING FROM A SET
// ----------------------------------------------------------------------------

/**
 * Works out which set this score is being played from, if any.
 *
 * A set that this device has never heard of is asked for once — a link into a
 * set can be followed on a device that has not synced since it was shared —
 * and, failing that, the score is shown for itself.
 *
 * @return {Promise<void>}
 */
async function _readSetContext() {
  const urlParams = new URLSearchParams(window.location.search);
  const setId = urlParams.get('set');
  if (setId == null) {
    return;
  }

  let set = app.setRepository.getSet(setId);
  if (set == null) {
    try {
      await app.updateSets();
    } catch (error) {
      console.error('failed to sync the sets', error);
    }
    set = app.setRepository.getSet(setId);
  }

  // Which entry it is has to have been said: a set with nothing said about
  // which of its entries this is, is a score that happens to be in a set, and
  // reading that as the first one would play it in the wrong key.
  const entryParam = urlParams.get('entry');
  const index = /^\d+$/.test(entryParam ?? '') ? Number(entryParam) : -1;
  if (set == null || index < 0 || index >= set.entries.length) {
    console.log(`no entry ${entryParam} in set ${setId}`);
    return;
  }

  setContext = {set, index, entry: set.entries[index]};
}

/** Writes the set controls, and points the way through the set. */
function _drawSetControls() {
  if (setContext == null) {
    setControls.hidden = true;
    return;
  }

  const {set, index, entry} = setContext;
  setControls.hidden = false;

  setButton.href = `../sets/detail.html?${new URLSearchParams({id: set.id}).toString()}`;
  setButton.innerText = set.title.trim() === '' ? 'Untitled set' : set.title;
  setPosition.innerText = `${index + 1} of ${set.entries.length}`;
  setEntryDescription.innerText = entry.description ?? '';

  _pointAt(setPreviousButton, index - 1);
  _pointAt(setNextButton, index + 1);

  // Everyone the set is shared with, not only whoever owns it: how a player
  // reads a song is theirs, and saying so changes nothing anybody else sees.
  saveViewToSetButton.hidden = false;

  _syncSetControls();
}

/**
 * How far the score is read from where it is written: the key the band plays it
 * in, plus how far this player reads it from there.
 *
 * The two are added rather than one replacing the other, and the sum is held to
 * the range the player offers — an octave either way is as far as the control
 * goes, whatever the two of them add up to.
 *
 * @param entry {import("../domains/sets/database.js").SetEntry}
 * @return {number}
 */
function _transpositionOfEntry(entry) {
  const band = entry.transposition ?? 0;
  const player = entry.view?.transposition ?? 0;
  return Math.min(MAX_TRANSPOSITION, Math.max(MIN_TRANSPOSITION, band + player));
}

/**
 * @param button {HTMLElement}
 * @param index {number}
 */
function _pointAt(button, index) {
  const set = setContext.set;
  if (index < 0 || index >= set.entries.length) {
    button.removeAttribute('href');
    button.setAttribute('aria-disabled', 'true');
    return;
  }

  button.removeAttribute('aria-disabled');
  button.href = `detail.html?${new URLSearchParams({
    id: set.entries[index].score_id,
    set: set.id,
    entry: `${index}`,
  }).toString()}`;
}

/**
 * Whether the way the score is on screen is the way the set says it is played.
 * While it is, there is nothing to save.
 */
function _syncSetControls() {
  if (setContext == null || scoreView == null) {
    return;
  }
  saveViewToSetButton.disabled = _viewMatchesEntry();
}

/** @return {boolean} */
function _viewMatchesEntry() {
  const hidden = setContext.entry.view?.hidden_parts ?? [];
  return _transpositionOfEntry(setContext.entry) === scoreView.transposition
    && hidden.length === scoreView.hiddenPartIds.length
    && hidden.every((partId) => scoreView.isHidden(partId));
}

/**
 * Writes the way this player is looking at the score into the set, so that it
 * opens that way the next time they play it.
 *
 * It is their own reading of it and nobody else's: the saxophone player saving
 * their key changes nothing for the pianist. Neither the score nor the set is
 * touched — what the band does is the owner's to say, and what is stored here
 * is only how far this player reads it from there, which is what is on screen
 * less the key the band plays it in.
 */
async function onSaveViewToSetClicked() {
  if (setContext == null || scoreView == null) {
    return;
  }

  const {set, index, entry} = setContext;
  saveViewToSetButton.disabled = true;
  try {
    const saved = await app.setRepository.saveEntryView(set.id, entry.id, {
      transposition: scoreView.transposition - (entry.transposition ?? 0),
      hidden_parts: [...scoreView.hiddenPartIds],
    });
    setContext = {set: saved, index, entry: saved.entries[index]};
    _drawSetControls();
  } catch (error) {
    console.error('failed to save how this score is read', error);
    alert(`This view could not be saved: ${error}`);
    _syncSetControls();
  }
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

async function onDownloadButtonClicked() {
  if (scoreId == null || musicXml == null) {
    alert('This score cannot be downloaded because it has not been loaded or saved yet.');
    return;
  }
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
    viewControls.hidden = true;
    console.log('no score viewer');
    return;
  }

  downloadButton.hidden = false;
  scoreMusicXml.hidden = false;

  if (scoreId != null) {
    musicXml = await app.scoreRepository.getMusicXml(scoreId);
    if (musicXml != null) {
      await _showScore(musicXml);
      if (setContext != null) {
        // The score opens the way the band plays it and the way this player
        // reads it: the entry says the band is a tone down, the view says this
        // player reads that a fifth up, and what goes on screen is the two
        // together.
        _queueViewChange((view) => view
          .withTransposition(_transpositionOfEntry(setContext.entry))
          .withHiddenParts(setContext.entry.view?.hidden_parts ?? []));
      }
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
  downloadButton.addEventListener('click', onDownloadButtonClicked);

  // Redrawing a score is expensive enough that doing it for every pixel of a
  // drag is not worth it, so dragging only moves the number and letting go
  // redraws.
  transpositionInput.addEventListener('input', _showTransposition);
  transpositionInput.addEventListener('change', () =>
    _queueViewChange((view) => view.withTransposition(Number(transpositionInput.value))));
  resetViewButton.addEventListener('click', () => _queueViewChange((view) => view.reset()));
  viewControls.addEventListener('toggle', _syncScoreOffset);
  window.addEventListener('resize', _syncScoreOffset);

  saveViewToSetButton.addEventListener('click', onSaveViewToSetClicked);

  const urlParams = new URLSearchParams(window.location.search);
  scoreId = urlParams.get('id');

  await _readSetContext();
  _drawSetControls();
  _syncScoreOffset();

  _initScoreEditor();
  await _initScoreViewer();
}

await main();

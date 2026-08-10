import {App} from "../app.js";
import {ScoreRenderer} from "../domains/scores/osmd-score-view.js";
import {musicXmlForView} from "../domains/scores/musicxml-view.js";
import {MAX_TRANSPOSITION, MIN_TRANSPOSITION} from "../domains/scores/score-view.js";

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
 * An entry is pointed at by its id rather than by where it comes in the set. An
 * id is the client's to name and stays that entry's for as long as the entry is
 * in the set, while the place it is played at moves under it every time
 * somebody reorders the gig — and a link that has been sitting in a browser
 * since before that would then open the right score and read it out of the
 * wrong entry.
 *
 * Where it comes in the set is still worth holding on to, since that is what
 * the way through the set is drawn from, but it is looked up from the id rather
 * than carried in the link.
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
  const entryId = urlParams.get('entry');
  const index = set?.entries.findIndex((candidate) => candidate.id === entryId) ?? -1;
  if (set == null || index < 0) {
    console.log(`no entry ${entryId} in set ${setId}`);
    return;
  }

  // The entry has to be an entry of this score. An entry can be written to
  // play a different score than it used to, and a link made before that would
  // otherwise hand this score the key and the hidden parts of a song it is
  // not. The score is what the page is of, so the set is what gives way.
  const entry = set.entries[index];
  if (entry.score_id !== scoreId) {
    console.log(`entry ${entryId} of set ${setId} is not this score`);
    return;
  }

  setContext = {set, index, entry};
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
    entry: set.entries[index].id,
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

  const {set, entry} = setContext;
  saveViewToSetButton.disabled = true;
  try {
    const saved = await app.setRepository.saveEntryView(set.id, entry.id, {
      transposition: scoreView.transposition - (entry.transposition ?? 0),
      hidden_parts: [...scoreView.hiddenPartIds],
    });
    // Where the entry comes in the set is read again rather than kept: a sync
    // can have reordered the gig while this was being written, and taking the
    // place it used to be at would put somebody else's song on the screen.
    const moved = saved.entries.findIndex((candidate) => candidate.id === entry.id);
    setContext = moved < 0 ? null : {set: saved, index: moved, entry: saved.entries[moved]};
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

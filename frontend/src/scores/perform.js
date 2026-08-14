import {App} from "../app.js";
import {ScoreRenderer} from "../domains/scores/osmd-score-view.js";
import {musicXmlForView} from "../domains/scores/musicxml-view.js";
import {MAX_TRANSPOSITION, MIN_TRANSPOSITION} from "../domains/scores/score-view.js";
import {clampZoom, DEFAULT_ZOOM, distanceBetween, Pinch} from "../domains/scores/pinch-zoom.js";
import {getScoreTitle} from "../data/helper-functions.js";

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-musicxml");
const renderer = new ScoreRenderer(osmd);

const backButton = document.getElementById('back-button');
const backToScoreIcon = document.getElementById('back-to-score-icon');
const backToSetIcon = document.getElementById('back-to-set-icon');
const scoreTitle = document.getElementById('score-title');
const scoreMusicXml = document.getElementById('score-musicxml');
const nothingNotice = document.getElementById('nothing-notice');
const paperNotice = document.getElementById('paper-notice');

const downloadMenu = document.getElementById('download-menu');
const downloadSvgButton = document.getElementById('download-svg-button');
const downloadMusicXmlButton = document.getElementById('download-musicxml-button');

const viewControls = document.getElementById('score-view-controls');
const transpositionInput = document.getElementById('transposition-input');
const transpositionOutput = document.getElementById('transposition-output');
const partsList = document.getElementById('parts-list');
const resetViewButton = document.getElementById('reset-view-button');

const songLine = document.getElementById('song-line');
const setName = document.getElementById('set-name');
const setPosition = document.getElementById('set-position');
const setPreviousButton = document.getElementById('set-previous-button');
const setNextButton = document.getElementById('set-next-button');
const setEntryDescription = document.getElementById('set-entry-description');
const readingState = document.getElementById('reading-state');

const app = new App('../config.json');

/**
 * The music-xml of the score as it was uploaded. Hiding parts and transposing
 * never touch it: they are applied to what OSMD draws, so this stays the
 * document the score is written back out of.
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
}

/**
 * Transposing and zooming both draw the score again, so one can still be
 * running when the next is asked for. They are queued rather than run over one
 * another, and each one is handed the score as it is by the time its turn comes
 * rather than as it was when it was asked for.
 *
 * @type {Promise<void>}
 */
let pendingRedraw = Promise.resolve();

/** @param redraw {function(): void|Promise<void>} */
function _queueRedraw(redraw) {
  pendingRedraw = pendingRedraw
    .then(redraw)
    .catch((error) => console.error('failed to draw the score again', error));
}

/**
 * @param change {function(import("../domains/scores/score-view.js").ScoreView):
 *   import("../domains/scores/score-view.js").ScoreView}
 */
function _queueViewChange(change) {
  _queueRedraw(() => _changeView(scoreView == null ? null : change(scoreView)));
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
    label.append(checkbox, document.createTextNode(part.name));

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

/** Writes the number on the transposition control, signed so up reads as up. */
function _showTransposition() {
  const semitones = Number(transpositionInput.value);
  transpositionOutput.textContent = semitones > 0 ? `+${semitones}` : `${semitones}`;
}

// ----------------------------------------------------------------------------
// HOW BIG THE MUSIC IS
// ----------------------------------------------------------------------------

/**
 * Where this device keeps the size it reads music at. How big a score has to be
 * drawn is about the player and the tablet on the stand rather than about the
 * score, so it is remembered here and used for every score that has nothing of
 * its own to say about it.
 */
const ZOOM_STORAGE_KEY = 'score-zoom';

/**
 * The pinch that is going on, if one is, and how big the music would be if the
 * fingers came off the glass right now.
 *
 * @type {import("../domains/scores/pinch-zoom.js").Pinch|null}
 */
let pinch = null;
let pinchedTo = DEFAULT_ZOOM;

/**
 * The size this device was reading music at when the page opened, which is what
 * a song nobody has said anything about is drawn at.
 *
 * It is read once rather than looked up as it goes: pinching writes the size
 * back, and a page that kept asking what the size is now would find the answer
 * moving under it and never notice that anything had changed.
 *
 * @type {number}
 */
let openingZoom = DEFAULT_ZOOM;

/**
 * A pinch is two fingers and nothing else, so a score is only ever drawn again
 * when the second one lands. One finger goes on scrolling the page the way it
 * always did.
 *
 * @param event {TouchEvent}
 */
function onTouchStart(event) {
  if (event.touches.length !== 2) {
    return;
  }

  const [first, second] = _fingers(event);
  pinch = Pinch.begin(renderer.zoom, distanceBetween(first, second));
  if (pinch == null) {
    return;
  }
  pinchedTo = renderer.zoom;

  // The music grows away from the point between the fingers, so whatever is
  // being looked at stays under them while the pinch is going on.
  const box = scoreMusicXml.getBoundingClientRect();
  scoreMusicXml.style.transformOrigin =
    `${(first.x + second.x) / 2 - box.left}px ${(first.y + second.y) / 2 - box.top}px`;
  scoreMusicXml.classList.add('is-pinching');
  event.preventDefault();
}

/**
 * Drawing a score takes long enough that doing it for every pixel of a pinch
 * would leave the music trailing behind the fingers, so the pinch stretches
 * what is already on screen and letting go draws it properly. What is stretched
 * is exactly what will be drawn, so nothing jumps in size at the end — only the
 * line breaks move.
 *
 * @param event {TouchEvent}
 */
function onTouchMove(event) {
  if (pinch == null || event.touches.length < 2) {
    return;
  }

  // Two fingers on the music mean this and nothing else: without saying so, the
  // page pans away under a pinch that is not perfectly still, and the browser
  // zooms the app itself rather than the score.
  event.preventDefault();

  const [first, second] = _fingers(event);
  const apart = distanceBetween(first, second);
  pinchedTo = pinch.zoomAt(apart);
  scoreMusicXml.style.transform = `scale(${pinch.scaleAt(apart)})`;
}

/** @param event {TouchEvent} */
function onTouchEnd(event) {
  if (pinch == null || event.touches.length >= 2) {
    return;
  }

  pinch = null;
  scoreMusicXml.classList.remove('is-pinching');
  scoreMusicXml.style.transform = '';
  scoreMusicXml.style.transformOrigin = '';
  // A pinch is this player saying what size they read at, so it is kept for the
  // next score they open as well as for this one.
  _queueRedraw(() => _zoomTo(pinchedTo, true));
}

/**
 * @param event {TouchEvent}
 * @return {{x: number, y: number}[]}
 */
function _fingers(event) {
  return [
    {x: event.touches[0].clientX, y: event.touches[0].clientY},
    {x: event.touches[1].clientX, y: event.touches[1].clientY},
  ];
}

/**
 * Draws the music at a different size and stays where the player was reading.
 *
 * Blowing a score up breaks it over more systems, so the bar that was on screen
 * is somewhere else on the page afterwards. There is no telling exactly where,
 * since the score is laid out afresh, but how far down the music it was is
 * about right and is a great deal better than being thrown back to the top of
 * the page mid-song.
 *
 * @param zoom {number}
 * @param remember {boolean} whether this is the size this device reads music
 *   at from now on. A pinch says so; opening a song at the size it was saved
 *   at says only what that song is read at, and should not quietly resize
 *   every other score on the device.
 */
function _zoomTo(zoom, remember = false) {
  const place = _placeInTheMusic();
  const drawn = renderer.setZoom(zoom);
  if (remember) {
    _rememberZoom(drawn);
  }
  _scrollToPlace(place);
  _syncSetControls();
}

/** @return {number} how far down the music the page is, as a fraction of it */
function _placeInTheMusic() {
  const height = scoreMusicXml.offsetHeight;
  if (height <= 0) {
    return 0;
  }
  return (window.scrollY - scoreMusicXml.offsetTop) / height;
}

/** @param place {number} */
function _scrollToPlace(place) {
  const top = scoreMusicXml.offsetTop + place * scoreMusicXml.offsetHeight;
  window.scrollTo({top: Math.max(0, top)});
}

/**
 * The size this device reads music at, or the size a score is written at when
 * it has never been said.
 *
 * @return {number}
 */
function _rememberedZoom() {
  try {
    const stored = localStorage.getItem(ZOOM_STORAGE_KEY);
    return stored == null ? DEFAULT_ZOOM : clampZoom(Number(stored));
  } catch (error) {
    console.error('failed to read the size music is read at', error);
    return DEFAULT_ZOOM;
  }
}

/** @param zoom {number} */
function _rememberZoom(zoom) {
  try {
    localStorage.setItem(ZOOM_STORAGE_KEY, `${zoom}`);
  } catch (error) {
    console.error('failed to remember the size music is read at', error);
  }
}

// ----------------------------------------------------------------------------
// PLAYING FROM A SET
// ----------------------------------------------------------------------------

/**
 * Works out which set this score is being played from, if any.
 *
 * A set that this device has never heard of is asked for once — a link into a
 * set can be followed on a device that has not synced since it was shared —
 * and, failing that, the score is played for itself.
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

/**
 * Where back goes: to the gig when the score was opened from one, and to the
 * score it is of otherwise.
 *
 * It is worked out in one place rather than by whoever runs last. Which set
 * this is comes from the link and the score comes from the database, and those
 * arrive at different moments — one of them writing the button on its way past
 * is how a button that says it goes back to the set ends up going somewhere
 * else.
 */
function _drawBackButton() {
  const goingToTheSet = setContext != null;
  const label = goingToTheSet ? 'Back to the set' : 'Back to the score';

  if (goingToTheSet) {
    backButton.href = _setUrl(setContext.set.id);
  } else if (scoreId != null) {
    backButton.href = `detail.html?${new URLSearchParams({id: scoreId}).toString()}`;
  }
  backButton.setAttribute('aria-label', label);
  backButton.title = label;

  // It shows where it goes rather than which way it points. Next to the arrow
  // that steps back through the running order, a second arrow is two ways back
  // and neither of them says which; a list is the gig, plainly.
  backToSetIcon.hidden = !goingToTheSet;
  backToScoreIcon.hidden = goingToTheSet;
}

/**
 * @param setId {string}
 * @return {string}
 */
function _setUrl(setId) {
  return `../sets/detail.html?${new URLSearchParams({id: setId}).toString()}`;
}

/**
 * Writes where in the gig this is, under the name of the song, and points the
 * way through the set.
 *
 * Which set it is, is said rather than linked: the back button goes there, and
 * two ways to the same place in one bar is one too many.
 */
function _drawSetControls() {
  if (setContext == null) {
    songLine.hidden = true;
    setPreviousButton.hidden = true;
    setNextButton.hidden = true;
    return;
  }

  const {set, index, entry} = setContext;
  songLine.hidden = false;
  setPreviousButton.hidden = false;
  setNextButton.hidden = false;

  setName.textContent = set.title.trim() === '' ? 'Untitled set' : set.title;
  setPosition.textContent = `${index + 1} of ${set.entries.length}`;
  // A song that is played from paper is called by its description, which is
  // already in the bar as the title. Saying it twice reads as two songs.
  setEntryDescription.textContent = entry.score_id == null ? '' : entry.description ?? '';

  _pointAt(setPreviousButton, index - 1);
  _pointAt(setNextButton, index + 1);

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

  // A song that is played off paper is still a song in the gig, so it is
  // stepped to like any other and says so when it gets there. Stepping over it
  // would have the player looking at the wrong song when the band starts the
  // next one.
  const next = set.entries[index];
  const where = {set: set.id, entry: next.id};
  if (next.score_id != null) {
    where.id = next.score_id;
  }
  button.href = `perform.html?${new URLSearchParams(where).toString()}`;
}

/**
 * Whether the way the score is on screen is the way the set says it is played.
 * While it is, there is nothing to write.
 */
function _syncSetControls() {
  if (setContext == null || scoreView == null || !readingIsSettled) {
    return;
  }
  if (!_viewMatchesEntry()) {
    _saveHowIReadIt();
  }
}

/**
 * Whether the score has finished opening the way the set says it is played.
 *
 * Until it has, what is on screen is the score as it was written, which is not
 * this player's reading of it — it is the page still catching up with the one
 * that was stored. Writing that back would have opening a song quietly throw
 * away the key it was saved in.
 *
 * @type {boolean}
 */
let readingIsSettled = false;



/** @return {boolean} */
function _viewMatchesEntry() {
  const hidden = setContext.entry.view?.hidden_parts ?? [];
  return _transpositionOfEntry(setContext.entry) === scoreView.transposition
    && _zoomOfEntry(setContext.entry) === renderer.zoom
    && hidden.length === scoreView.hiddenPartIds.length
    && hidden.every((partId) => scoreView.isHidden(partId));
}

/**
 * How big this player has said they read this one, or the size they read music
 * at in general when they have never said.
 *
 * Unlike the key, this is not counted on top of anything the band says: how
 * close somebody is sitting to their screen is not something a band decides.
 *
 * @param entry {import("../domains/sets/database.js").SetEntry}
 * @return {number}
 */
function _zoomOfEntry(entry) {
  return entry.view?.zoom == null ? openingZoom : clampZoom(entry.view.zoom);
}

/**
 * How this player is looking at the score is written into the set as they
 * change it, the way everything else about a set is written as it is changed.
 * There is nothing to press: transposing a song at a gig and then having to
 * remember to say so is a way of losing it.
 *
 * It is their own reading of it and nobody else's: the saxophone player's key
 * changes nothing for the pianist. Neither the score nor the set is touched —
 * what the band does is the owner's to say, and what is stored here is only how
 * far this player reads it from there, which is what is on screen less the key
 * the band plays it in.
 *
 * The writes are held back a moment rather than made as they come. Dragging the
 * transposition across an octave and pinching a score to size are a handful of
 * changes each, and what is worth storing is where they came to rest.
 */
const HOW_LONG_BEFORE_WRITING = 400;

/** How long a word about it stays on the page before it goes away again. */
const HOW_LONG_A_WORD_STAYS = 2500;

/** @type {number|null} */
let pendingReadingWrite = null;

/** @type {number|null} */
let readingStateTimer = null;

/**
 * What was last written, so that the same reading is never written twice.
 *
 * Not every reading can be stored exactly — a key that adds up past the octave
 * is read at the edge instead — so a page that only ever asked whether the
 * screen matches the set would write the same thing over and over for as long
 * as it was open.
 *
 * @type {{transposition: number, hidden_parts: string[], zoom: number}|null}
 */
let lastWrittenReading = null;

function _saveHowIReadIt() {
  if (!readingIsSettled) {
    return;
  }
  if (pendingReadingWrite != null) {
    clearTimeout(pendingReadingWrite);
  }
  pendingReadingWrite = setTimeout(_writeHowIReadIt, HOW_LONG_BEFORE_WRITING);
}

/**
 * Writes a reading that is waiting on the clock right now.
 *
 * A song is left by walking to the next one in the gig, and the page is gone
 * the moment that is tapped. Whatever was still waiting to be written is what
 * the player just did to the song they are about to play, so it goes now.
 */
function _writeAnythingWaiting() {
  if (pendingReadingWrite == null) {
    return;
  }
  clearTimeout(pendingReadingWrite);
  _writeHowIReadIt();
}

/**
 * @return {{transposition: number, hidden_parts: string[], zoom: number}}
 */
function _howIReadIt() {
  return {
    transposition: scoreView.transposition - (setContext.entry.transposition ?? 0),
    hidden_parts: [...scoreView.hiddenPartIds],
    zoom: renderer.zoom,
  };
}

async function _writeHowIReadIt() {
  pendingReadingWrite = null;
  if (setContext == null || scoreView == null) {
    return;
  }

  const reading = _howIReadIt();
  if (_isTheSameReading(reading, lastWrittenReading)) {
    return;
  }
  lastWrittenReading = reading;

  const {set, entry} = setContext;
  try {
    const saved = await app.setRepository.saveEntryView(set.id, entry.id, reading);
    // Where the entry comes in the set is read again rather than kept: a sync
    // can have reordered the gig while this was being written, and taking the
    // place it used to be at would put somebody else's song on the screen.
    const moved = saved.entries.findIndex((candidate) => candidate.id === entry.id);
    setContext = moved < 0 ? null : {set: saved, index: moved, entry: saved.entries[moved]};
    _drawSetControls();
    _showReadingState('Saved as how you read it');
  } catch (error) {
    console.error('failed to save how this score is read', error);
    // It was not written, so the next change is worth trying again with.
    lastWrittenReading = null;
    _showReadingState('How you read this one could not be saved', true);
  }
}

/**
 * @param a {{transposition: number, hidden_parts: string[], zoom: number}|null}
 * @param b {{transposition: number, hidden_parts: string[], zoom: number}|null}
 * @return {boolean}
 */
function _isTheSameReading(a, b) {
  return a != null && b != null
    && a.transposition === b.transposition
    && a.zoom === b.zoom
    && a.hidden_parts.length === b.hidden_parts.length
    && a.hidden_parts.every((partId) => b.hidden_parts.includes(partId));
}

/**
 * A word about what just happened to the reading, which goes away again.
 *
 * It is said quietly and briefly: this is a page somebody is playing from, and
 * a message that stays on it is one more thing on the stand. A failure stays,
 * since that is the one worth looking up for.
 *
 * @param message {string}
 * @param failed {boolean}
 */
function _showReadingState(message, failed = false) {
  readingState.textContent = message;
  readingState.hidden = false;
  readingState.classList.toggle('reading-state--failed', failed);

  if (readingStateTimer != null) {
    clearTimeout(readingStateTimer);
    readingStateTimer = null;
  }
  if (!failed) {
    readingStateTimer = setTimeout(() => {
      readingState.hidden = true;
    }, HOW_LONG_A_WORD_STAYS);
  }
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
    alert('This score cannot be downloaded because it has not been loaded yet.');
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

// ----------------------------------------------------------------------------
// OPENING THE PAGE
// ----------------------------------------------------------------------------

/**
 * Whatever the song is called, in the bar and in the tab.
 *
 * A song that is played off paper has no score to take a title from, so what is
 * written next to it in the running order is what it is called. One that has
 * neither is still a song in the gig — a blank line in a set list is a thing
 * people write — and is called what it is: the next one.
 */
function _drawScoreTitle() {
  const score = app.scoreRepository.scores.find((candidate) => candidate.id === scoreId);
  let title = score == null ? null : getScoreTitle(score);

  if (title == null && _isPlayedOffPaper()) {
    const written = `${setContext.entry.description ?? ''}`.trim();
    title = written === '' ? 'A song of the set' : written;
  }
  if (title == null) {
    return;
  }

  scoreTitle.textContent = title;
  document.title = title;
}

/**
 * Whether what is being played here is a song this app has no score of: one in
 * a folder on the stand. It is a song of the gig like any other, so the way
 * through the set steps to it and this page says what it is when it arrives.
 *
 * @return {boolean}
 */
function _isPlayedOffPaper() {
  return scoreId == null && setContext != null && setContext.entry.score_id == null;
}

async function _openScore() {
  if (app.user?.isScoreViewer !== true) {
    nothingNotice.hidden = false;
    console.log('no score viewer');
    return;
  }

  if (_isPlayedOffPaper()) {
    // There is nothing to draw and nothing to transpose, but there is still a
    // song, a place in the gig and a way on to the next one. The view controls
    // stay away: they are controls of a score, and there is no score here.
    paperNotice.hidden = false;
    return;
  }

  if (scoreId == null) {
    nothingNotice.hidden = false;
    return;
  }

  musicXml = await app.scoreRepository.getMusicXml(scoreId);
  if (musicXml == null) {
    nothingNotice.hidden = false;
    return;
  }

  scoreMusicXml.hidden = false;
  downloadMenu.hidden = false;

  await _showScore(musicXml);

  if (setContext != null) {
    // The score opens the way the band plays it and the way this player reads
    // it: the entry says the band is a tone down, the view says this player
    // reads that a fifth up, and what goes on screen is the two together. How
    // big it is drawn is this player's alone and is not added to anything.
    _queueRedraw(() => _zoomTo(_zoomOfEntry(setContext.entry)));
    _queueViewChange((view) => view
      .withTransposition(_transpositionOfEntry(setContext.entry))
      .withHiddenParts(setContext.entry.view?.hidden_parts ?? []));
    // Only now is what is on screen this player's reading of the song rather
    // than the page still opening it. Anything they do to it from here is
    // theirs, and is written as they do it.
    _queueRedraw(() => {
      readingIsSettled = true;
    });
  } else {
    readingIsSettled = true;
  }

  try {
    await app.scoreRepository.updateScoreLastViewedAt(scoreId);
  } catch (error) {
    console.error('Failed to update score last viewed timestamp for scoreId:', scoreId, error);
  }
}

async function main() {
  await app.initialize();

  downloadSvgButton.addEventListener('click', onDownloadSvgClicked);
  downloadMusicXmlButton.addEventListener('click', onDownloadMusicXmlClicked);
  _syncDownloadMenu();

  // A menu left open over the music is in the way, and clicking off it is how a
  // menu is put away.
  document.addEventListener('click', (event) => {
    for (const menu of document.querySelectorAll('.menu[open]')) {
      if (!menu.contains(event.target)) {
        menu.open = false;
      }
    }
  });

  // Redrawing a score is expensive enough that doing it for every pixel of a
  // drag is not worth it, so dragging only moves the number and letting go
  // redraws.
  transpositionInput.addEventListener('input', _showTransposition);
  transpositionInput.addEventListener('change', () =>
    _queueViewChange((view) => view.withTransposition(Number(transpositionInput.value))));
  resetViewButton.addEventListener('click', () => _queueViewChange((view) => view.reset()));

  // Walking to the next song of the gig, putting the tablet down, closing the
  // page: all of them end this page, and a reading that was still waiting on
  // the clock has to go before it does.
  window.addEventListener('pagehide', _writeAnythingWaiting);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') {
      _writeAnythingWaiting();
    }
  });

  // A pinch is two fingers on the music, and the browser would otherwise take
  // them for its own zoom, so both of these are told they were listened to.
  scoreMusicXml.addEventListener('touchstart', onTouchStart, {passive: false});
  scoreMusicXml.addEventListener('touchmove', onTouchMove, {passive: false});
  scoreMusicXml.addEventListener('touchend', onTouchEnd);
  scoreMusicXml.addEventListener('touchcancel', onTouchEnd);
  openingZoom = _rememberedZoom();
  renderer.setZoom(openingZoom);

  const urlParams = new URLSearchParams(window.location.search);
  scoreId = urlParams.get('id');

  _drawScoreTitle();
  await _readSetContext();
  _drawBackButton();
  _drawSetControls();

  await _openScore();
  _drawScoreTitle();

  await app.updateScores();
  _drawScoreTitle();
}

await main();

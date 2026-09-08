import {html, nothing, render} from "../packages/lit-core.3.3.3.min.js";
import {App} from "../app.js";
import {keepAppUpToDate} from "../domains/updates/app-update.js";
import {getScoreTitle} from "../data/helper-functions.js";
import {getInstrumentName, getLanguageName} from "../data/translations.js";
import {Settings} from "../domains/settings/settings.js";

// There is sheet music on this page, so how the page it is drawn on is lit is
// this page's business too, exactly as it is the playing page's.
Settings.apply();

/**
 * What a score is, apart from playing it.
 *
 * Reading the music is a thing you do standing up with an instrument in your
 * hands, and it has a page of its own that gets out of the way. This one is for
 * everything you want to know before you get there — including the first bars,
 * because a title and a composer identify a piece only to somebody who knows it
 * already — and for the two things only an editor does: putting the file there,
 * and putting a better one there.
 *
 * The whole page is one function of one score, re-run whenever the score
 * changes. There is nothing to keep in step by hand, bar the paper the opening
 * is drawn on; see {@link previewSheet}.
 */

const detail = document.getElementById('detail');
const topbarTitle = document.querySelector('.topbar-title');

const app = new App('../config.json');

/** @type {string|null} */
let scoreId = null;

/** @type {import("../domains/scores/database.js").Score|null} */
let score = null;

/** The file an editor has chosen but not sent yet. @type {File|null} */
let chosenFile = null;

/** @type {string|null} */
let chosenXml = null;

/** Whether a write is in flight, so the button can say so. */
let uploading = false;

/** @type {string|null} */
let uploadError = null;

// ----------------------------------------------------------------------------
// THE OPENING BARS
// ----------------------------------------------------------------------------

/**
 * How many bars are worth drawing here.
 *
 * Enough to know the piece by, and no further. The whole of a score would be a
 * page of scrolling in the middle of a page of facts, and the page that is for
 * reading the whole of it is one tap away.
 *
 * @type {number}
 */
const PREVIEW_MEASURES = 16;

/**
 * How big the bars are drawn, where 1 is the size the music is played at.
 *
 * It follows the width of the paper rather than being one number. A phone and a
 * laptop are handed the same music and the same box, and one size is wrong on
 * one of them: the size that fits a laptop puts a single bar across a phone with
 * the notes the size of a thumb. Following the width keeps roughly the same
 * number of bars on a line whatever it is read on. It stops at both ends so a
 * very narrow phone still gets notes anybody can make out, and a wide screen
 * does not end up drawing the opening at the size it is played at.
 *
 * @param width {number} how wide the paper is, in pixels
 * @return {number}
 */
function _previewZoom(width) {
  return Math.min(0.75, Math.max(0.4, width / 800));
}

/**
 * The paper the opening is drawn on.
 *
 * Made once, and deliberately not made by the template. The engine that draws
 * sheet music writes into this element, and a template that re-rendered over it
 * — because the sets finished syncing, say — would wipe the drawing. Handing
 * lit the element itself rather than markup for one means lit moves it about
 * and never rebuilds it.
 *
 * @type {HTMLDivElement}
 */
const previewSheet = document.createElement('div');
previewSheet.className = 'preview-sheet';

/** @type {'idle'|'drawing'|'drawn'|'missing'|'failed'} */
let previewState = 'idle';

/** Whether there is more music below the bottom of the box. */
let previewIsClipped = false;

/** The engine being fetched, so two askings share one fetch. @type {Promise<void>|null} */
let engineArriving = null;

// ----------------------------------------------------------------------------
// DRAWING THE PAGE
// ----------------------------------------------------------------------------

function _draw() {
  render(_page(), detail);

  const title = score == null ? 'Score' : getScoreTitle(score);
  topbarTitle.textContent = scoreId == null ? 'New score' : title;
  document.title = scoreId == null ? 'New score' : title;
}

function _page() {
  if (app.user?.isScoreViewer !== true) {
    return html`
      <p class="muted">You are not allowed to read scores. Ask whoever runs this
        for the score viewer role, then open your
        <a href="../profile.html">profile</a> to check it arrived.</p>`;
  }

  // A score that is being uploaded for the first time has nothing to say about
  // itself yet: everything on this page is read out of the document, and there
  // is no document.
  if (scoreId == null) {
    return html`
      <h1>New score</h1>
      <p class="muted">Choose a MusicXML file. What it is called, who wrote it
        and what it is for are all read out of the file itself.</p>
      ${_fileCard('Upload')}`;
  }

  if (score == null) {
    return html`
      <p class="muted">This score is not on this device.</p>
      <p class="muted">If it was shared with you recently, it will appear once
        this device has synced. <a href="/">Back to the list</a></p>`;
  }

  return html`
    ${_hero()}
    ${_preview()}
    ${_facts()}
    ${_sets()}
    ${app.user?.isScoreEditor === true ? _fileCard('Replace the file') : nothing}`;
}

function _hero() {
  const movement = score.movement?.title;
  const play = `perform.html?${new URLSearchParams({id: scoreId}).toString()}`;

  return html`
    <div class="hero">
      <div class="hero-title stack stack--tight">
        <h1>${getScoreTitle(score)}</h1>
        ${movement == null || movement.trim() === ''
          ? nothing
          : html`<span class="hero-movement">${movement}</span>`}
      </div>
      <a class="button button--primary" href=${play}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" width="18" height="18"
             aria-hidden="true" focusable="false" style="fill: currentColor">
          <path d="M4 2l14 8l-14 8z"/>
        </svg>
        Play
      </a>
    </div>`;
}

/**
 * The first bars, as they are actually written.
 *
 * The whole of it is a way through to the playing page, because what somebody
 * does after recognising a piece is open it — and because a picture of music
 * that is not a button to the music is a thing to be tapped and be disappointed
 * by.
 *
 * Nothing at all until there is something to say: the section appears when the
 * drawing starts, so a page that has only just been opened does not flash an
 * empty frame at the reader.
 *
 * @return {unknown}
 */
function _preview() {
  if (previewState === 'idle') {
    return nothing;
  }

  if (previewState === 'missing') {
    return _previewSection(html`
      <p class="muted">The music itself is not on this device yet. It arrives
        the next time this device syncs while it can reach the server.</p>`);
  }

  if (previewState === 'failed') {
    return _previewSection(html`
      <p class="muted">These bars could not be drawn. Nothing has happened to
        the score — it still opens on the playing page.</p>`);
  }

  const play = `perform.html?${new URLSearchParams({id: scoreId}).toString()}`;
  return _previewSection(html`
    ${previewState === 'drawing'
      ? html`<p class="muted">Drawing the first bars…</p>`
      : nothing}
    <a class="preview ${previewIsClipped ? 'preview--clipped' : ''}" href=${play}
       aria-label="Open the music">
      ${previewSheet}
    </a>`);
}

/**
 * @param body {unknown}
 * @return {unknown}
 */
function _previewSection(body) {
  return html`
    <div class="stack stack--tight">
      <span class="section-title">The opening</span>
      ${body}
    </div>`;
}

/**
 * Draws the opening bars, fetching the engine that draws them on the way.
 *
 * That engine is a megabyte, which is a lot to ask of a page that is otherwise
 * a list of names — so it is asked for here, once there is a score to draw, and
 * never at all by somebody who came to this page to upload one. It is the same
 * file the playing page uses and the service worker already keeps, so on a
 * device that has opened a score before, fetching it costs nothing.
 *
 * @return {Promise<void>}
 */
async function _drawTheOpening() {
  previewState = 'drawing';

  // The engine lays the music out to the width of the paper it is given, so the
  // paper has to be on the page before any of the rest of this. This is what
  // puts it there.
  _draw();

  let musicXml = null;
  try {
    musicXml = await app.scoreRepository.getMusicXml(scoreId);
  } catch (error) {
    console.error('failed to read the music', error);
  }

  if (musicXml == null) {
    previewState = 'missing';
    _draw();
    return;
  }

  try {
    await _theEngine();
    const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay(previewSheet, {
      // What a piece is called, who wrote it and which movement this is are
      // already the top of this page. Drawn again above the staff they would be
      // the same three lines twice over, and they would be most of the box.
      drawTitle: false,
      drawSubtitle: false,
      drawComposer: false,
      drawLyricist: false,
      drawUpToMeasureNumber: PREVIEW_MEASURES,
    });
    await osmd.load(musicXml);
    // After reading and not before: reading a score sets the size back to the
    // engine's own, so a size said first is a size that never reaches the page.
    osmd.Zoom = _previewZoom(previewSheet.clientWidth);
    osmd.render();
  } catch (error) {
    console.error('failed to draw the opening bars', error);
    previewState = 'failed';
    _draw();
    return;
  }

  previewState = 'drawn';
  // Whether the music runs off the bottom of the box is only knowable once it
  // has been drawn, and it is what says whether the box fades out or simply
  // ends.
  const box = previewSheet.parentElement;
  previewIsClipped = box != null && previewSheet.scrollHeight > box.clientHeight + 1;
  _draw();
}

/**
 * The engine that draws sheet music, fetched the first time it is wanted.
 *
 * It is a plain script that hangs a name on the window rather than a module, so
 * this waits for the tag rather than importing anything.
 *
 * @return {Promise<void>}
 */
function _theEngine() {
  if (globalThis.opensheetmusicdisplay != null) {
    return Promise.resolve();
  }
  if (engineArriving != null) {
    return engineArriving;
  }

  engineArriving = new Promise((arrived, failed) => {
    const script = document.createElement('script');
    script.src = '../packages/open_sheet_music_display.1.8.9.min.js';
    script.addEventListener('load', () => arrived());
    script.addEventListener('error', () => {
      // Forgotten rather than remembered as broken: a device that was offline
      // when this page opened may not be by the time it is asked again.
      engineArriving = null;
      failed(new Error('the engine that draws sheet music could not be fetched'));
    });
    document.head.appendChild(script);
  });
  return engineArriving;
}

function _facts() {
  const composers = score.creators?.composers ?? [];
  const lyricists = score.creators?.lyricists ?? [];
  const instruments = (score.instruments ?? []).map((one) => getInstrumentName(one));
  const languages = (score.languages ?? [])
    .map((one) => getLanguageName(one))
    .filter((one) => one !== '');

  return html`
    <div class="card facts">
      ${_fact('Composers', composers.join(', '))}
      ${lyricists.length === 0 ? nothing : _fact('Lyricists', lyricists.join(', '))}
      ${_fact('Instruments', instruments.join(', '))}
      ${languages.length === 0 ? nothing : _fact('Languages', languages.join(', '))}
      ${_fact('Last changed', _when(score.last_changed_at))}
      ${(score.tags ?? []).length === 0 ? nothing : html`
        <div class="fact">
          <span class="label">Tags</span>
          <div class="tags">
            ${score.tags.map((tag) => html`<span class="chip">${tag}</span>`)}
          </div>
        </div>`}
    </div>`;
}

/**
 * @param label {string}
 * @param value {string}
 * @return {unknown}
 */
function _fact(label, value) {
  const said = value != null && value.trim() !== '';
  return html`
    <div class="fact">
      <span class="label">${label}</span>
      <span class="fact-value ${said ? '' : 'fact-value--quiet'}">
        ${said ? value : 'Not said'}
      </span>
    </div>`;
}

/**
 * Which gigs this one is played at. A score knows nothing about the sets it is
 * in — a set names scores and not the other way about — so this is read off the
 * sets this device has.
 */
function _sets() {
  const playedIn = app.setRepository.sets
    .flatMap((set) => set.entries
      .filter((entry) => entry.score_id === scoreId)
      .map((entry) => ({set, entry})));

  if (playedIn.length === 0) {
    return nothing;
  }

  return html`
    <div class="stack stack--tight">
      <span class="section-title">Played in</span>
      <div class="set-links">
        ${playedIn.map(({set, entry}) => html`
          <a class="chip set-link"
             href="perform.html?${new URLSearchParams({
               id: scoreId, set: set.id, entry: entry.id,
             }).toString()}">
            ${set.title.trim() === '' ? 'Untitled set' : set.title}
          </a>`)}
      </div>
    </div>`;
}

/**
 * Putting a document there, or a better one.
 *
 * What is chosen is not drawn here before it is sent. The engine that draws
 * sheet music is fetched for a score that is already up, where it says which
 * piece this is; a file that is only on its way up is not that yet, and the
 * score opens on the playing page the moment it is written anyway.
 *
 * @param action {string}
 * @return {unknown}
 */
function _fileCard(action) {
  return html`
    <div class="card stack">
      <span class="section-title">${action}</span>

      <div class="file-field">
        <input type="file" id="file-input" accept=".musicxml" @change=${onFileChosen}/>
        <button type="button" class="button button--primary"
                ?disabled=${chosenXml == null || uploading}
                @click=${onUploadClicked}>
          ${uploading ? 'Sending…' : action}
        </button>
      </div>

      ${chosenFile == null ? nothing : html`
        <p class="muted">Ready to send: ${chosenFile.name}</p>`}
      ${uploadError == null ? nothing : html`
        <p class="muted" style="color: var(--danger)">${uploadError}</p>`}
    </div>`;
}

/**
 * A moment, said the way the reader's own device says dates.
 *
 * What arrives is meant to be a date, and everywhere it is written it is one.
 * It is read back out of a database though, and a moment that has been through
 * a string at any point in its life comes back as one — so this takes either
 * rather than letting the whole page die on a date.
 *
 * @param moment {Date|string|null}
 * @return {string}
 */
function _when(moment) {
  if (moment == null) {
    return '';
  }
  const date = moment instanceof Date ? moment : new Date(moment);
  return Number.isNaN(date.getTime())
    ? ''
    : date.toLocaleDateString(undefined, {year: 'numeric', month: 'long', day: 'numeric'});
}

// ----------------------------------------------------------------------------
// PUTTING A SCORE THERE
// ----------------------------------------------------------------------------

/**
 * @param event {Event}
 */
function onFileChosen(event) {
  uploadError = null;
  chosenFile = null;
  chosenXml = null;

  const file = event.target.files[0];
  if (file == null) {
    _draw();
    return;
  }

  if (!file.name.toLowerCase().endsWith('.musicxml')) {
    uploadError = 'That is not a MusicXML file. Choose a file ending in .musicxml.';
    _draw();
    return;
  }

  chosenFile = file;
  _draw();

  // Read it here rather than at the moment of sending: a file that cannot be
  // read is worth knowing about while the file picker is still in mind.
  const reader = new FileReader();
  reader.onload = (loaded) => {
    chosenXml = loaded.target.result;
    _draw();
  };
  reader.onerror = () => {
    uploadError = 'That file could not be read.';
    chosenFile = null;
    _draw();
  };
  reader.readAsText(file);
}

async function onUploadClicked() {
  if (chosenXml == null || uploading) {
    return;
  }

  const user = await app.updateAuth();
  if (await user?.isScoreEditor !== true) {
    uploadError = 'You are not allowed to write scores.';
    _draw();
    return;
  }

  uploading = true;
  uploadError = null;
  _draw();

  // A score that has never been written needs a name to be written under, and
  // the client is what names it.
  const writingTo = scoreId ?? crypto.randomUUID();
  try {
    const accessToken = await app.oidcApi.getActiveAccessToken();
    await app.scoresApi.putScore(writingTo, accessToken, chosenXml);
  } catch (error) {
    console.error('failed to write the score', error);
    uploading = false;
    uploadError = `That score could not be sent: ${error.message ?? error}`;
    _draw();
    return;
  }

  // Straight to the music: it is the only way to see that what arrived is what
  // was meant, and it is where somebody putting a score up is going next.
  window.location = `perform.html?${new URLSearchParams({id: writingTo}).toString()}`;
}

// ----------------------------------------------------------------------------
// OPENING THE PAGE
// ----------------------------------------------------------------------------

function _readScore() {
  score = scoreId == null
    ? null
    : app.scoreRepository.scores.find((candidate) => candidate.id === scoreId) ?? null;
}

/**
 * The opening is drawn as soon as there is a score to draw it from, which is
 * straight away on a device that already has this one and only after a sync on
 * a device that has just been given it.
 *
 * Once, then, and not again — with one exception. A score whose music had not
 * arrived yet is asked about again every time the scores change, because a sync
 * that has since fetched the document is exactly the moment worth trying on. A
 * drawing that went wrong is not retried: it will go wrong the same way.
 */
function _maybeDrawTheOpening() {
  if (scoreId == null || score == null || app.user?.isScoreViewer !== true) {
    return;
  }
  if (previewState !== 'idle' && previewState !== 'missing') {
    return;
  }
  _drawTheOpening()
    .catch((error) => console.error('failed to draw the opening bars', error));
}

async function main() {
  // Fetched but never taken while this page is open: there is a form on it, and
  // a reload would empty it.
  keepAppUpToDate()
    .catch((error) => console.error('failed to watch for a newer app', error));

  await app.initialize();

  scoreId = new URLSearchParams(window.location.search).get('id');

  app.scoreRepository.addScoreChangesListener(() => {
    _readScore();
    _draw();
    _maybeDrawTheOpening();
  });

  _readScore();
  _draw();
  _maybeDrawTheOpening();

  if (app.user?.isScoreViewer !== true) {
    return;
  }

  // What is on screen is what this device has; syncing only ever adds to it.
  try {
    await app.updateScores();
  } catch (error) {
    console.error('failed to sync the scores', error);
  }

  // The sets are what says where this one is played, and they are worth having
  // even though nothing on this page can change them.
  try {
    await app.updateSets();
  } catch (error) {
    console.error('failed to sync the sets', error);
  }

  _readScore();
  _draw();
  _maybeDrawTheOpening();
}

await main();

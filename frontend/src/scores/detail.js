import {html, nothing, render} from "../packages/lit-core.3.3.3.min.js";
import {App} from "../app.js";
import {getScoreTitle} from "../data/helper-functions.js";
import {getInstrumentName} from "../data/translations.js";

/**
 * What a score is, apart from the notes.
 *
 * The music is not drawn here. Reading it is a thing you do standing up with an
 * instrument in your hands, and it has a page of its own that gets out of the
 * way; this one is for everything you want to know before you get there, and
 * for the two things only an editor does — putting the file there, and putting
 * a better one there.
 *
 * The whole page is one function of one score, re-run whenever the score
 * changes. There is nothing to keep in step by hand.
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

function _facts() {
  const composers = score.creators?.composers ?? [];
  const lyricists = score.creators?.lyricists ?? [];
  const instruments = (score.instruments ?? []).map((one) => getInstrumentName(one));

  return html`
    <div class="card facts">
      ${_fact('Composers', composers.join(', '))}
      ${lyricists.length === 0 ? nothing : _fact('Lyricists', lyricists.join(', '))}
      ${_fact('Instruments', instruments.join(', '))}
      ${(score.languages ?? []).length === 0
        ? nothing
        : _fact('Languages', score.languages.join(', '))}
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
 * What is chosen is not drawn here before it is sent. Drawing it would mean
 * this page carrying the whole engine that draws sheet music, which is a
 * megabyte to open a page that is mostly a list of names — and the score opens
 * on the playing page the moment it is written anyway.
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

async function main() {
  await app.initialize();

  scoreId = new URLSearchParams(window.location.search).get('id');

  app.scoreRepository.addScoreChangesListener(() => {
    _readScore();
    _draw();
  });

  _readScore();
  _draw();

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
}

await main();

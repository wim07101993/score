import {buildScoreCard} from "./components/score-card.component.js";
import {App} from "./app.js";
import {keepAppUpToDate} from "./domains/updates/app-update.js";
import {html, nothing, render} from "./packages/lit-core.3.3.3.min.js";
import {getScoreTitle, scoreMatches} from "./data/helper-functions.js";
import {getInstrumentName} from "./data/translations.js";

const uploadButton = document.getElementById('upload-button');
const setsButton = document.getElementById('sets-button');
const collectionsButton = document.getElementById('collections-button');
const scoreList = document.getElementById('score-list');
const emptyNotice = document.getElementById('empty-notice');
const searchRow = document.getElementById('search-row');
const searchInput = document.getElementById('score-search');
const searchNotice = document.getElementById('search-notice');
const filtersPanel = document.getElementById('filters');
const filtersDetails = document.getElementById('filters-details');
const filtersSummary = document.getElementById('filters-summary');
const filtersBody = document.getElementById('filters-body');
const filingDialog = document.getElementById('filing-dialog');
const filingBody = document.getElementById('filing-body');

const app = new App('config.json');

/**
 * The score whose sets and collections are open, or `null` when nothing is.
 *
 * @type {import("./domains/scores/database.js").Score|null}
 */
let filingScore = null;

/** Whether a write to a set or a collection is in flight. */
let filing = false;

/** @type {string|null} */
let filingError = null;

/** What has been typed into the search box. @type {string} */
let searchFor = '';

/**
 * The fields a library can be narrowed by, and how to read one off a score.
 *
 * Everything here is something a score says about itself in words that repeat:
 * two scores by the same composer say the same name, and a hundred scores say
 * a dozen names between them. That is what makes a list of them worth ticking,
 * and it is why the title is not among them — every score has a different one,
 * and a list of every title is the list of scores again.
 *
 * The instruments are read as their names rather than the sounds MusicXML
 * writes, so that what is ticked is what the rows say.
 *
 * @type {{key: string, title: string, of: function(Object): string[]}[]}
 */
const FIELDS = [
  {key: 'composers', title: 'Composers', of: (score) => score.creators?.composers ?? []},
  {key: 'lyricists', title: 'Lyricists', of: (score) => score.creators?.lyricists ?? []},
  {
    key: 'instruments',
    title: 'Instruments',
    of: (score) => (score.instruments ?? []).map((one) => getInstrumentName(one)),
  },
  {key: 'languages', title: 'Languages', of: (score) => score.languages ?? []},
  {key: 'tags', title: 'Tags', of: (score) => score.tags ?? []},
];

/**
 * How many of a field's values are offered before the rest are folded away. A
 * library of a few hundred scores has more composers than a sidebar has room
 * for, and the ones worth ticking are the ones that keep coming up.
 *
 * @type {number}
 */
const valuesShownAtFirst = 8;

/**
 * What has been ticked, by field. A field nobody has ticked anything in is a
 * field that is not narrowing the list.
 *
 * @type {Map<string, Set<string>>}
 */
const ticked = new Map(FIELDS.map((field) => [field.key, new Set()]));

/**
 * The fields whose values are all being offered, rather than the first few.
 *
 * @type {Set<string>}
 */
const unfolded = new Set();

function _buildScoreListItems() {
  scoreList.replaceChildren();
  const sortedScores = app.scoreRepository.scores.sort((a, b) => (b.last_viewed_at ?? 0) - (a.last_viewed_at ?? 0));
  const showing = _narrowed(sortedScores);
  // A row only offers a way into the sets and collections for somebody who has
  // any: a reader who cannot see a set has nothing to put a score into.
  const filable = app.user?.isScoreViewer === true;
  for (const score of showing) {
    scoreList.appendChild(buildScoreCard(score, {filable: filable}));
  }

  emptyNotice.hidden = sortedScores.length > 0;
  // An empty list is a bordered box with nothing in it, which reads as
  // something that failed to load rather than as a library nobody has filled
  // yet. The notice says that better on its own.
  scoreList.hidden = showing.length === 0 || app.user?.isScoreViewer !== true;
  _sayWhatIsShowing(showing.length, sortedScores.length);
  _drawFilters(sortedScores);
}

// ----------------------------------------------------------------------------
// LOOKING FOR ONE SCORE
// ----------------------------------------------------------------------------

/**
 * The scores that are being shown: the ones the search finds, narrowed by
 * everything that has been ticked.
 *
 * Ticking two composers asks for either of them and ticking a composer and an
 * instrument asks for both, which is what ticking things means: two boxes in
 * one list widen it, and a box in a second list narrows what the first let
 * through.
 *
 * @param scores {Object[]}
 * @param except {Object|null} a field to leave out of the narrowing, so that a
 *   field's own values can be counted against everything but itself. Ticking a
 *   second composer has to be possible, and it would not be if the values were
 *   counted against a list the first composer had already narrowed.
 * @return {Object[]}
 */
function _narrowed(scores, except = null) {
  return scores.filter((score) => scoreMatches(score, searchFor)
    && FIELDS.every((field) => field === except || _passes(score, field)));
}

/**
 * @param score {Object}
 * @param field {{key: string, of: function(Object): string[]}}
 * @return {boolean}
 */
function _passes(score, field) {
  const chosen = ticked.get(field.key);
  if (chosen == null || chosen.size === 0) {
    return true;
  }
  return field.of(score).some((value) => chosen.has(value));
}

/** @return {number} how many boxes are ticked, across every field. */
function _tickedCount() {
  let count = 0;
  for (const chosen of ticked.values()) {
    count += chosen.size;
  }
  return count;
}

// ----------------------------------------------------------------------------
// THE WORDS THE LIBRARY IS MADE OF
// ----------------------------------------------------------------------------

/**
 * Draws the sidebar: every field the library has values for, and how many
 * scores each value would leave.
 *
 * The counts are what the sidebar is for. A list of composers says who is in
 * the library; a list of composers with numbers beside them says which of them
 * this library is actually made of, and answers "have I got anything for two
 * voices in dutch" before anybody clicks.
 *
 * @param scores {Object[]} every score on this device
 */
function _drawFilters(scores) {
  const fields = FIELDS
    .map((field) => ({field: field, values: _valuesOf(field, scores)}))
    .filter((one) => one.values.length > 0);

  // Nothing to narrow: a library of one score, or one that says nothing about
  // itself beyond its title, is not a library to sift.
  filtersPanel.hidden = fields.length === 0
    || scores.length === 0
    || app.user?.isScoreViewer !== true;
  if (filtersPanel.hidden) {
    return;
  }

  const chosen = _tickedCount();
  // Said on the summary because on a phone the summary may be all there is to
  // see: a list that has been narrowed by something folded away is a list that
  // looks like it has lost half the library.
  filtersSummary.textContent = chosen === 0 ? 'Filters' : `Filters (${chosen})`;

  render(html`
    ${chosen === 0 ? nothing : html`
      <button type="button" class="button button--quiet filters-clear"
              @click=${_clearFilters}>Clear all
      </button>`}
    ${fields.map((one) => _fieldSection(one.field, one.values))}`, filtersBody);
}

/**
 * One field, as a heading and a list of what it holds.
 *
 * @param field {{key: string, title: string}}
 * @param values {{value: string, count: number}[]}
 * @return {unknown}
 */
function _fieldSection(field, values) {
  const showing = unfolded.has(field.key) ? values : values.slice(0, valuesShownAtFirst);
  const folded = values.length - showing.length;

  return html`
    <div class="filter-field">
      <span class="label">${field.title}</span>
      ${showing.map((one) => _valueRow(field, one))}
      ${folded <= 0 ? nothing : html`
        <button type="button" class="button button--quiet filter-more"
                @click=${() => _unfold(field)}>${folded} more
        </button>`}
      ${!unfolded.has(field.key) || values.length <= valuesShownAtFirst ? nothing : html`
        <button type="button" class="button button--quiet filter-more"
                @click=${() => _fold(field)}>Fewer
        </button>`}
    </div>`;
}

/**
 * @param field {{key: string, title: string}}
 * @param one {{value: string, count: number}}
 * @return {unknown}
 */
function _valueRow(field, one) {
  const chosen = ticked.get(field.key).has(one.value);
  return html`
    <label class="filter-row">
      <input type="checkbox" .checked=${chosen}
             @change=${(event) => _tick(field, one.value, event.target.checked)}/>
      <span class="filter-row-title" title=${one.value}>${one.value}</span>
      <span class="filter-count">${one.count}</span>
    </label>`;
}

/**
 * What a field holds, most often first, and what each of them would leave on
 * the screen.
 *
 * Counted against the list as it stands without this field's own ticks, so that
 * a second value in the same field can be added to the first. A value that has
 * been ticked is offered whatever it counts: something has to be there to untick.
 *
 * @param field {{key: string, of: function(Object): string[]}}
 * @param scores {Object[]}
 * @return {{value: string, count: number}[]}
 */
function _valuesOf(field, scores) {
  const counts = new Map();
  for (const score of _narrowed(scores, field)) {
    // A score that names the same composer twice is one score by that composer.
    for (const value of new Set(field.of(score))) {
      if (`${value}`.trim() === '') {
        continue;
      }
      counts.set(value, (counts.get(value) ?? 0) + 1);
    }
  }

  for (const value of ticked.get(field.key)) {
    if (!counts.has(value)) {
      counts.set(value, 0);
    }
  }

  return Array.from(counts.entries())
    .map(([value, count]) => ({value: value, count: count}))
    .sort((a, b) => b.count - a.count || a.value.localeCompare(b.value));
}

/**
 * @param field {{key: string}}
 * @param value {string}
 * @param wanted {boolean}
 */
function _tick(field, value, wanted) {
  const chosen = ticked.get(field.key);
  if (wanted) {
    chosen.add(value);
  } else {
    chosen.delete(value);
  }
  _buildScoreListItems();
}

/** @param field {{key: string}} */
function _unfold(field) {
  unfolded.add(field.key);
  _buildScoreListItems();
}

/** @param field {{key: string}} */
function _fold(field) {
  unfolded.delete(field.key);
  _buildScoreListItems();
}

function _clearFilters() {
  for (const chosen of ticked.values()) {
    chosen.clear();
  }
  _buildScoreListItems();
}

/**
 * How much of the library is on the screen.
 *
 * Only while something is being looked for: a list that says "40 of 40" under
 * it every time it is opened is a list with a number under it for no reason.
 *
 * @param showing {number}
 * @param held {number}
 */
function _sayWhatIsShowing(showing, held) {
  // Nothing to search until there is something to search through, and nobody
  // who cannot read the scores has anything to look for.
  searchRow.hidden = held === 0 || app.user?.isScoreViewer !== true;
  if (searchRow.hidden) {
    searchNotice.hidden = true;
    return;
  }

  // Nothing is being said while nothing is being left out: a list with
  // "40 of 40" under it every time it is opened is a number for no reason.
  if (showing === held) {
    searchNotice.hidden = true;
    return;
  }

  searchNotice.hidden = false;
  if (showing > 0) {
    searchNotice.textContent = `${showing} of ${held} scores.`;
    return;
  }

  searchNotice.textContent = searchFor.trim() === ''
    ? 'Nothing here matches what you are asking for.'
    : `Nothing here matches “${searchFor.trim()}”.`;
}

function _initScoreEditor() {
  if (app.user?.isScoreEditor !== true) {
    uploadButton.hidden = true;
    console.log('no score editor');
    return
  }

  uploadButton.hidden = false;
}

async function _initScoreViewer() {
  if (app.user?.isScoreViewer !== true) {
    scoreList.hidden = true;
    setsButton.hidden = true;
    collectionsButton.hidden = true;
    emptyNotice.hidden = true;
    console.log('no score viewer');
    return;
  }

  // A set and a collection name scores but change nothing about them, so
  // keeping one asks no more of a user than reading the scores in it.
  setsButton.hidden = false;
  collectionsButton.hidden = false;
  scoreList.hidden = false;
  _buildScoreListItems();

  // What is on screen is what this device has; syncing only ever adds to it. So
  // a server that refuses — a token that has run out is the usual way — costs
  // this page whatever is new, and nothing that was already here.
  try {
    await app.updateScores();
  } catch (error) {
    console.error('failed to sync the scores', error);
  }
}

// ----------------------------------------------------------------------------
// PUTTING A SCORE INTO A SET OR A COLLECTION
// ----------------------------------------------------------------------------

/**
 * Opens the sets and collections of one score.
 *
 * Both at once, on purpose. They are different things — a set is a gig, a
 * collection is a book — but the question being asked of the library is the
 * same one, and answering it twice in two places would mean opening the piece,
 * finding the gig, coming back, and finding the book.
 *
 * @param score {import("./domains/scores/database.js").Score}
 */
function _openFiling(score) {
  filingScore = score;
  filingError = null;
  _drawFiling();
  filingDialog.showModal();
}

function _closeFiling() {
  filingDialog.close();
}

function _drawFiling() {
  render(_filingPage(), filingBody);
}

function _filingPage() {
  if (filingScore == null) {
    return nothing;
  }

  // Only what this user is allowed to arrange. A set that was shared with them
  // is somebody else's running order, and offering to change it would be
  // offering a write the repository refuses.
  const sets = app.setRepository.sets.filter((set) => set.is_owner !== false);
  const collections = app.collectionRepository.collections
    .filter((collection) => collection.is_owner !== false);

  return html`
    <div class="filing-head">
      <div class="stack stack--tight">
        <span class="section-title">Put this score into</span>
        <strong class="filing-title">${getScoreTitle(filingScore)}</strong>
      </div>
      <button type="button" class="button button--quiet button--icon" aria-label="Close"
              @click=${_closeFiling}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true"
             focusable="false">
          <path d="M18.3 5.71L12 12l6.3 6.29l-1.41 1.42L10.59 13.4L4.3 19.71L2.88 18.3L9.17 12L2.88 5.71L4.3 4.3l6.29 6.29l6.3-6.29z"/>
        </svg>
      </button>
    </div>

    ${sets.length === 0 && collections.length === 0 ? html`
      <p class="muted">You have no sets or collections yet. Make one on the
        <a href="sets/">sets</a> or <a href="collections/">collections</a> page,
        and it will be offered here.</p>` : nothing}

    ${sets.length === 0 ? nothing : html`
      <div class="filing-group">
        <span class="label">Sets</span>
        ${sets.map((set) => _filingRow(
          set.title.trim() === '' ? 'Untitled set' : set.title,
          set.entries.filter((entry) => entry.score_id === filingScore.id).length,
          true,
          () => _fileInSet(set)))}
      </div>`}

    ${collections.length === 0 ? nothing : html`
      <div class="filing-group">
        <span class="label">Collections</span>
        ${collections.map((collection) => {
          const held = collection.entries
            .filter((entry) => entry.score_id === filingScore.id).length;
          return _filingRow(
            collection.title.trim() === '' ? 'Untitled collection' : collection.title,
            held,
            // A collection holds a piece once: it is a book, and a book does
            // not have the same piece printed in it twice.
            held === 0,
            () => _fileInCollection(collection));
        })}
      </div>`}

    ${filingError == null ? nothing : html`
      <p class="muted" style="color: var(--danger)">${filingError}</p>`}

    <p class="muted">Taking a piece out again is done on the set's or the
      collection's own page, where what else is in it can be seen.</p>`;
}

/**
 * One set or collection, and a way to put this score into it.
 *
 * A button rather than a tick. A tick says whether a piece belongs in there,
 * which is a question with one answer — and a gig that plays the same song
 * twice has no way to say so. A button says "put it in", which is what this is
 * for, and pressing it again puts it in again.
 *
 * Nothing here takes a piece out. That is done where what else is in the set
 * can be seen, next to the order it is played in: a piece removed from behind a
 * list of names is a piece removed without looking at what it was next to.
 *
 * @param title {string}
 * @param held {number} how many times it already holds this score.
 * @param canHoldMore {boolean} whether it takes another one. A gig may play a
 *   piece twice; a book holds it once.
 * @param onAdd {function(): Promise<void>}
 * @return {unknown}
 */
function _filingRow(title, held, canHoldMore, onAdd) {
  return html`
    <div class="filing-row">
      <span class="filing-row-title" title=${title}>${title}</span>
      ${held === 0 ? nothing : html`
        <span class="chip">${held === 1 ? 'in it' : `in it ${held}×`}</span>`}
      ${canHoldMore ? html`
        <button type="button" class="button filing-add" ?disabled=${filing}
                aria-label=${`Put it into ${title}`}
                @click=${onAdd}>Add
        </button>` : nothing}
    </div>`;
}

/**
 * Puts the score at the end of a set's running order, which is where a song
 * that has just been chosen goes: what is played when is decided on the set's
 * own page, where the order can be seen.
 *
 * A set takes it again however often it is asked. Half a gig is a piece played
 * once; the other half is the one that opens the second half as well.
 *
 * @param set {import("./domains/sets/database.js").ScoreSet}
 */
async function _fileInSet(set) {
  const scoreId = filingScore.id;
  await _write(() => app.setRepository.saveEntry(set.id, {score_id: scoreId}));
}

/**
 * @param collection {import("./domains/collections/database.js").Collection}
 */
async function _fileInCollection(collection) {
  const scoreId = filingScore.id;
  await _write(() => app.collectionRepository.saveEntry(collection.id, {score_id: scoreId}));
}

/**
 * Makes a change to a set or a collection and draws whatever came of it.
 *
 * The write goes to this device first and to the server when there is one, so
 * a piece that has just been put into a gig stays in it on a stand with no
 * network. What cannot be done at all — a set that is not this user's to
 * arrange — is said here, and the rows are drawn again from what is actually
 * stored rather than from what was pressed.
 *
 * @param write {function(): Promise<void>}
 */
async function _write(write) {
  filing = true;
  filingError = null;
  _drawFiling();

  try {
    await write();
  } catch (error) {
    console.error('failed to file the score', error);
    filingError = `That could not be written: ${error.message ?? error}`;
  }

  filing = false;
  _drawFiling();
  // The rows say which sets and collections a score is in, so they are behind
  // as soon as this is.
  _buildScoreListItems();
}

async function main() {
  // Before anything that can fail, and before anything the reader might be in
  // the middle of: this is a list of scores and the way in to everything else,
  // so it is the page that can be swapped for a newer one without asking.
  keepAppUpToDate({reloadWhenReplaced: true})
    .catch((error) => console.error('failed to watch for a newer app', error));

  await app.initialize();

  app.scoreRepository.addScoreChangesListener(() => _buildScoreListItems());

  searchInput.addEventListener('input', () => {
    searchFor = searchInput.value;
    _buildScoreListItems();
  });

  // Open where there is room beside the list, folded away where there is not.
  // It is set when the page opens and when the screen crosses that width — a
  // phone turned on its side is a different page — and left alone in between,
  // so that closing it stays closed.
  const roomBeside = window.matchMedia('(min-width: 52rem)');
  filtersDetails.open = roomBeside.matches;
  roomBeside.addEventListener('change', (event) => (filtersDetails.open = event.matches));

  // A row says which piece was pointed at and nothing else; what there is to
  // put it into is this page's to know.
  scoreList.addEventListener('file-score', (event) => _openFiling(event.detail.score));
  // A dialog that is dismissed with the escape key closes without anybody
  // clicking anything, and what is drawn in it is about a score that is no
  // longer being asked about.
  filingDialog.addEventListener('close', () => {
    filingScore = null;
    filingError = null;
    _drawFiling();
  });
  // Everywhere else in this app the backdrop of a sheet is a way out of it.
  filingDialog.addEventListener('click', (event) => {
    if (event.target === filingDialog) {
      _closeFiling();
    }
  });
  // A sync that arrives while the sheet is open changes the answer it is
  // giving: a set made on another device belongs in the list, and one that is
  // gone should stop being offered.
  app.setRepository.addSetsChangesListener(() => _drawFiling());
  app.collectionRepository.addCollectionsChangesListener(() => _drawFiling());

  _initScoreEditor();
  await _initScoreViewer();

  // Whatever was written to a set or a collection while there was nothing to
  // send it to is still owed to the server, and any page with a network is a
  // chance to send it: waiting for the player to open them again is waiting for
  // nothing.
  if (app.user?.isScoreViewer === true) {
    try {
      await app.updateSets();
    } catch (error) {
      console.error('failed to sync the sets', error);
    }
    try {
      await app.updateCollections();
    } catch (error) {
      console.error('failed to sync the collections', error);
    }
  }
}

await main();

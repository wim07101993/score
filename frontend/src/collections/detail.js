import {App} from "../app.js";
import {keepAppUpToDate} from "../domains/updates/app-update.js";
import {forSearch, getScoreTitle} from "../data/helper-functions.js";
import {buildScoreDetails} from "../components/score-details.js";
import {MAX_TRANSPOSITION, MIN_TRANSPOSITION} from "../domains/scores/score-view.js";
import {ScoreAlreadyInCollectionError} from "../domains/collections/repository.js";

const collectionState = document.getElementById('collection-state');
const saveButton = document.getElementById('save-button');
const collectionDetail = document.getElementById('collection-detail');
const forbiddenNotice = document.getElementById('forbidden-notice');

const titleInput = document.getElementById('title-input');
const descriptionInput = document.getElementById('description-input');
const sharedWithInput = document.getElementById('shared-with-input');

const entriesList = document.getElementById('entries-list');
const noEntriesNotice = document.getElementById('no-entries-notice');
const unsavedCollectionNotice = document.getElementById('unsaved-collection-notice');

const scoreFilter = document.getElementById('score-filter');
const scorePicker = document.getElementById('score-picker');
const noScoresNotice = document.getElementById('no-scores-notice');
const paperEntryInput = document.getElementById('paper-entry-input');
const addPaperEntryButton = document.getElementById('add-paper-entry-button');

const sharingSection = document.getElementById('sharing-section');
const addScoreSection = document.getElementById('add-score-section');
const deleteSection = document.getElementById('delete-section');
const deleteButton = document.getElementById('delete-button');

const app = new App('../config.json');

/**
 * What the collection is, as it is being typed: the group of pieces, and who
 * may read it. It is not stored until the save button says so.
 *
 * What is in the collection is not here. An entry is written on its own, so
 * adding a piece, taking one out, and changing its note or key each land as
 * they are made — there is nothing to save afterwards, and nothing to lose by
 * leaving the page. What is drawn for them is read from the collection as it is
 * stored, never from here.
 *
 * @type {{id: string, title: string, description: string, shared_with: string[]}}
 */
let draft;

/** Whether the draft says something the stored collection does not. */
let dirty = false;

/** Whether this collection is this user's to change. @type {boolean} */
let isOwner = true;

/**
 * Whether the collection is stored at all. One that is not is one there is
 * nothing to put a piece into yet: what is in it hangs off a collection, and
 * the collection has to exist first.
 */
let isStored = false;

// ----------------------------------------------------------------------------
// THE COLLECTION AS A WHOLE
// ----------------------------------------------------------------------------

/**
 * @param collection {import('../domains/collections/database.js').Collection|null}
 * @param collectionId {string|null}
 */
function _readDraftFrom(collection, collectionId) {
  draft = {
    id: collection?.id ?? collectionId ?? crypto.randomUUID(),
    title: collection?.title ?? '',
    description: collection?.description ?? '',
    shared_with: [...(collection?.shared_with ?? [])],
  };
  isOwner = collection == null || collection.is_owner !== false;
  isStored = collection != null;
  dirty = false;
}

/** The collection as it is stored, which is where what is in it is read from. */
function _stored() {
  return app.collectionRepository.getCollection(draft.id);
}

/**
 * What is in the collection, by title.
 *
 * A collection has no order, so this is not one: it is the order a list
 * somebody is looking through should be in. The titles are in the scores rather
 * than in the entries, which is why the sorting is here rather than in the
 * repository — a piece with no score is filed under what is written next to it,
 * which is the only name it has.
 *
 * @return {import('../domains/collections/database.js').CollectionEntry[]}
 */
function _entries() {
  return [...(_stored()?.entries ?? [])]
    .sort((a, b) => _nameOf(a).localeCompare(_nameOf(b)));
}

/**
 * Whatever a piece is called: the title of its score, and what is written next
 * to it when there is no score to take a title from.
 *
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {string}
 */
function _nameOf(entry) {
  if (entry.score_id == null) {
    const written = `${entry.description ?? ''}`.trim();
    return written === '' ? 'A piece, not scanned yet' : written;
  }
  const score = app.scoreRepository.scores.find((candidate) => candidate.id === entry.score_id);
  return score == null ? 'Not on this device yet' : getScoreTitle(score);
}

/** Writes the whole page. */
function _draw() {
  titleInput.value = draft.title;
  descriptionInput.value = draft.description;
  sharedWithInput.value = draft.shared_with.join('\n');

  _drawEntries();
  _drawScorePicker();
  _drawState();
}

function _drawState() {
  const stored = _stored();
  const owed = stored != null && (
    stored.pending_change != null
    || stored.pending_entries?.length > 0
    || stored.pending_views?.length > 0);

  if (!isOwner) {
    // Not read-only: what is in it is theirs, but how you read it is yours.
    collectionState.innerText = owed
      ? 'shared with you — your own reading of it is not sent yet'
      : 'shared with you';
  } else if (dirty) {
    collectionState.innerText = 'not saved';
  } else if (stored == null) {
    collectionState.innerText = 'new collection';
  } else if (owed) {
    collectionState.innerText = 'saved here, not sent yet';
  } else {
    collectionState.innerText = 'saved';
  }

  saveButton.disabled = !isOwner || !dirty;
  saveButton.hidden = !isOwner;
  deleteSection.hidden = !isOwner || !isStored;
  sharingSection.hidden = !isOwner;
  addScoreSection.hidden = !isOwner || !isStored;
  unsavedCollectionNotice.hidden = isStored || !isOwner;

  // Whose the collection is, is something a sync can change its mind about, so
  // this is drawn from the collection rather than settled once when the page is
  // opened.
  titleInput.disabled = !isOwner;
  descriptionInput.disabled = !isOwner;
  sharedWithInput.disabled = !isOwner;
}

/**
 * Something was typed into what the collection is. That is the only thing here
 * that waits for a save button, and the only thing leaving the page could lose.
 */
function _markDirty() {
  dirty = true;
  _drawState();
}

// ----------------------------------------------------------------------------
// THE PIECES THAT ARE IN IT
// ----------------------------------------------------------------------------

function _drawEntries() {
  const entries = _entries();
  const typing = _fieldBeingTypedIn();

  entriesList.replaceChildren();
  noEntriesNotice.hidden = entries.length > 0 || !isStored;

  for (const entry of entries) {
    const item = document.createElement('li');
    item.appendChild(_buildEntry(entry));
    entriesList.appendChild(item);
  }

  _goOnTypingIn(typing);
}

/**
 * Which box the player is typing in, so that it can be found again in the list
 * that is about to replace this one.
 *
 * Every piece of a collection is written as it is changed, and a write draws
 * the list afresh — so clicking out of one piece's note and straight into the
 * next one's writes the first, throws away every box on the page, and leaves
 * the cursor in a box that no longer exists. Which piece and which of its boxes
 * it was, is what survives that; where the boxes happen to be in the list is
 * not, since renaming a piece can move it.
 *
 * @return {{entryId: string, field: string, start: number|null,
 *   end: number|null}|null} null when nobody is typing in one
 */
function _fieldBeingTypedIn() {
  const focused = document.activeElement;
  const entry = focused?.closest?.('.entry');
  if (entry == null || focused.dataset.field == null) {
    return null;
  }

  return {
    entryId: entry.dataset.entryId,
    field: focused.dataset.field,
    start: _cursorAt(focused, 'selectionStart'),
    end: _cursorAt(focused, 'selectionEnd'),
  };
}

/**
 * Where the cursor is in a box, and nothing for a box that has no answer to
 * that: a number box refuses to be asked, and putting a cursor back in one is
 * not worth an exception.
 *
 * @param input {HTMLInputElement}
 * @param which {string}
 * @return {number|null}
 */
function _cursorAt(input, which) {
  try {
    return input[which];
  } catch {
    return null;
  }
}

/**
 * Puts the cursor back where it was, in the box that has taken the place of the
 * one it was in.
 *
 * A box that is no longer there — its piece was taken out of the collection —
 * is left alone rather than guessed at.
 *
 * @param typing {{entryId: string, field: string, start: number|null,
 *   end: number|null}|null}
 */
function _goOnTypingIn(typing) {
  if (typing == null) {
    return;
  }

  const entry = entriesList.querySelector(
    `.entry[data-entry-id="${CSS.escape(typing.entryId)}"]`);
  const input = entry?.querySelector(`[data-field="${CSS.escape(typing.field)}"]`);
  if (input == null || input.disabled) {
    return;
  }

  input.focus();
  if (typing.start != null && input.setSelectionRange != null) {
    input.setSelectionRange(typing.start, typing.end);
  }
}

/**
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {HTMLElement}
 */
function _buildEntry(entry) {
  const container = document.createElement('div');
  container.className = 'entry';
  // Which piece this is, so that the box somebody is typing in can be found
  // again after the list has been drawn afresh.
  container.dataset.entryId = entry.id;

  const score = entry.score_id == null
    ? null
    : app.scoreRepository.scores.find((candidate) => candidate.id === entry.score_id);
  const title = document.createElement('span');
  title.className = 'entry-title';
  if (entry.score_id == null) {
    // A piece that has yet to be scanned. It has no score to take a title from,
    // so it is called by what is written next to it — and one nobody has
    // written anything next to yet is still a piece in the collection.
    title.classList.add('entry-on-paper');
    title.innerText = _nameOf(entry);
    title.title = 'Not scanned yet; there is no score here to open.';
  } else if (score == null) {
    title.classList.add('entry-missing');
    title.innerText = 'Not on this device yet';
    title.title = entry.score_id;
  } else {
    title.innerText = getScoreTitle(score);
  }

  // What the piece is, as much of it as the list of scores says: a book is
  // looked through by who wrote what is in it as much as by what it is called,
  // and that is the same handful of words either way.
  const what = document.createElement('span');
  what.className = 'entry-what';
  what.append(title, ...buildScoreDetails(score));

  container.append(what, _buildEntryButtons(entry), _buildEntryControls(entry));
  return container;
}

/**
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {HTMLElement}
 */
function _buildEntryButtons(entry) {
  const buttons = document.createElement('span');
  buttons.className = 'entry-buttons';

  const open = document.createElement('a');
  open.className = 'entry-open';
  open.innerText = 'open';
  open.href = _entryUrl(entry);
  buttons.appendChild(open);

  if (!isOwner) {
    return buttons;
  }

  // No moving: a collection has no order, so there is nowhere to move a piece
  // to. Taking one out is all there is.
  buttons.appendChild(_button('✕', 'Take out of the collection', false, async () => {
    try {
      await app.collectionRepository.deleteEntry(draft.id, entry.id);
    } catch (error) {
      console.error('failed to take the piece out of the collection', error);
      alert(`That piece could not be taken out of the collection: ${error}`);
    }
    _drawEntries();
    _drawScorePicker();
    _drawState();
  }));
  return buttons;
}

/**
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {HTMLElement}
 */
function _buildEntryControls(entry) {
  const controls = document.createElement('span');
  controls.className = 'entry-controls';

  const description = document.createElement('input');
  description.type = 'text';
  description.className = 'entry-description';
  description.dataset.field = 'description';
  description.value = entry.description;
  // For a piece with no score this box is not a note about it, it is its name,
  // so it says so — and it cannot be emptied: a book has nowhere for a piece to
  // come, so an unnamed one cannot be found or told from the next unnamed one.
  const isTheOnlyName = entry.score_id == null;
  description.placeholder = isTheOnlyName
    ? 'what this piece is called'
    : 'page 214, in the red folder, the arrangement we do';
  description.disabled = !isOwner;
  // On change rather than on input: every one of these is a write of that
  // piece, and a write per keystroke is a write per keystroke.
  description.addEventListener('change', () => {
    if (isTheOnlyName && description.value.trim() === '') {
      // Put the name back rather than refusing out loud. Nobody meant to leave
      // a piece of a book with nothing to call it; they meant to type over it.
      description.value = entry.description;
      description.select();
      return;
    }
    _writeEntry({id: entry.id, description: description.value});
  });

  controls.append(description, _buildTransposition(entry), _buildParts(entry));
  return controls;
}

/**
 * How far the piece is read from where it is written, which is two numbers and
 * not one: the key the group plays it in, and how far this player reads it from
 * there. They are shown in the order they add, with the sum spelled out — on
 * their own they are a pair of bare boxes, and nobody should have to work out
 * that the second is counted on top of the first or that either is semitones.
 *
 * The player's half is written on its own rather than with the collection: a
 * view says nothing about the collection and changes nothing anybody else sees,
 * so everyone it is shared with can set their own — a player who cannot add a
 * piece to the book still reads it in the key their instrument is in.
 *
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {HTMLElement}
 */
function _buildTransposition(entry) {
  const group = document.createElement('span');
  group.className = 'entry-transpose';
  group.appendChild(document.createTextNode('transpose'));

  // What the group does, which is the owner's to say and the same for everyone.
  const band = _numberInput(entry.transposition, !isOwner, 'band', (semitones) =>
    _writeEntry({id: entry.id, transposition: semitones}));
  group.appendChild(_transpositionField('all', band,
    'The key this one is played in, counted in semitones from where it is written. Everyone sees this.'));

  const plus = document.createElement('span');
  plus.className = 'entry-transpose-plus';
  plus.innerText = '+';
  group.appendChild(plus);

  // What this player does on top of it, which is theirs and nobody else's.
  const mine = _numberInput(entry.view.transposition, false, 'me', (semitones) =>
    _saveMyView(entry.id, {transposition: semitones, hidden_parts: entry.view.hidden_parts}));
  group.appendChild(_transpositionField('me', mine,
    'How far you read it on top of that, again in semitones. Only you see this.'));

  group.appendChild(_transpositionTotal(entry));
  return group;
}

/**
 * @param text {string}
 * @param input {HTMLElement}
 * @param title {string}
 * @return {HTMLElement}
 */
function _transpositionField(text, input, title) {
  const field = document.createElement('label');
  field.className = 'entry-transpose-field';
  field.title = title;
  field.append(document.createTextNode(text), input);
  return field;
}

/**
 * What the two of them come to, which is the only one of these numbers the
 * player is going to hear: it is the key the score opens at for them.
 *
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {HTMLElement}
 */
function _transpositionTotal(entry) {
  const total = document.createElement('span');
  total.className = 'entry-transpose-total';
  total.title = 'What the two of them come to: the key this one opens at for you.';

  const sum = entry.transposition + entry.view.transposition;
  const read = Math.min(MAX_TRANSPOSITION, Math.max(MIN_TRANSPOSITION, sum));
  if (read === 0) {
    total.innerText = '= as written';
  } else {
    total.innerText = `= ${read > 0 ? '+' : ''}${read} semitones`;
  }

  if (read !== sum) {
    total.innerText += ' (as far as it goes)';
    total.classList.add('entry-transpose-clamped');
  }
  return total;
}

/**
 * Which parts of the piece this player has off their screen, which is theirs
 * and nobody else's in the same way the key they read it in is.
 *
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {HTMLElement}
 */
function _buildParts(entry) {
  const parts = document.createElement('span');
  parts.className = 'entry-parts';

  // Which parts are off screen is not something to pick from a list here: the
  // parts a score has are in its document, and the document is not read until
  // the score is drawn. So it is set while playing — on the score itself — and
  // all this says is how it stands and how to undo it.
  const hidden = entry.view.hidden_parts.length;
  parts.append(document.createTextNode(hidden === 0
    ? 'every part on your screen'
    : `${hidden} ${hidden === 1 ? 'part' : 'parts'} off your screen`));

  if (hidden > 0) {
    parts.appendChild(_button('show all', 'Put every part back on your screen', false, () =>
      _saveMyView(entry.id, {transposition: entry.view.transposition, hidden_parts: []})));
  }

  return parts;
}

/**
 * Writes one piece of the collection. Everything about an entry is written as
 * it is changed rather than waiting for a save button: an entry is a resource
 * of its own, so there is nothing it has to be saved along with.
 *
 * A piece the collection already holds is not an error to show: it is what the
 * player wanted, so the entry it is already in is what they are taken to.
 *
 * @param entry {{id?: string, score_id?: string|null, description?: string,
 *   transposition?: number}}
 * @return {Promise<void>}
 */
async function _writeEntry(entry) {
  try {
    await app.collectionRepository.saveEntry(draft.id, entry);
  } catch (error) {
    if (error instanceof ScoreAlreadyInCollectionError) {
      _pointAtEntry(error.entryId);
      return;
    }
    console.error('failed to write the piece into the collection', error);
    alert(`That piece could not be put into the collection: ${error}`);
  }
  _drawEntries();
  _drawScorePicker();
  _drawState();
}

/**
 * Shows the player the piece they just asked for, which is already here.
 *
 * A collection holds a piece once, so adding one that is in it is not a
 * refusal — it is being told where it is. Scrolling to it and lighting it for a
 * moment says that without a dialog to dismiss.
 *
 * @param entryId {string}
 */
function _pointAtEntry(entryId) {
  const entry = entriesList.querySelector(`.entry[data-entry-id="${CSS.escape(entryId)}"]`);
  if (entry == null) {
    return;
  }
  entry.scrollIntoView({behavior: 'smooth', block: 'center'});
  entry.classList.remove('entry--pointed-at');
  // Reading the layout between taking the class off and putting it back is what
  // restarts the animation; without it, pointing at the same piece twice does
  // nothing the second time.
  void entry.offsetWidth;
  entry.classList.add('entry--pointed-at');
}

/**
 * Stores how this player reads one entry.
 *
 * A view is written whole rather than a field at a time, so what the caller has
 * not said is filled in from how the entry is read now. Saying only that the
 * key has changed is not saying to read the piece at the size every other one
 * is drawn at, or to put the parts that are off screen back on it.
 *
 * @param entryId {string}
 * @param view {{transposition?: number, hidden_parts?: string[],
 *   zoom?: number}}
 * @return {Promise<void>}
 */
async function _saveMyView(entryId, view) {
  const read = _entries().find((candidate) => candidate.id === entryId)?.view;
  const whole = {
    transposition: view.transposition ?? read?.transposition ?? 0,
    hidden_parts: view.hidden_parts ?? read?.hidden_parts ?? [],
    zoom: view.zoom ?? read?.zoom ?? 1,
  };

  try {
    await app.collectionRepository.saveEntryView(draft.id, entryId, whole);
  } catch (error) {
    console.error('failed to save how this entry is read', error);
    alert(`How you read this one could not be saved: ${error}`);
  }
  _drawEntries();
  _drawState();
}

/**
 * @param semitones {number}
 * @param disabled {boolean}
 * @param field {string} which of an entry's boxes this is, so that it can be
 *   found again after the list is drawn afresh
 * @param onChange {function(number)}
 * @return {HTMLElement}
 */
function _numberInput(semitones, disabled, field, onChange) {
  const input = document.createElement('input');
  input.type = 'number';
  input.className = 'entry-transposition';
  input.dataset.field = field;
  input.min = `${MIN_TRANSPOSITION}`;
  input.max = `${MAX_TRANSPOSITION}`;
  input.step = '1';
  input.value = `${semitones}`;
  input.disabled = disabled;
  input.addEventListener('change', () => {
    const asked = _transpositionOf(input.value);
    input.value = `${asked}`;
    onChange(asked);
  });
  return input;
}

/**
 * Where a piece is opened from. An entry is pointed at by its id, which stays
 * that entry's for as long as it is in the collection.
 *
 * @param entry {import('../domains/collections/database.js').CollectionEntry}
 * @return {string}
 */
function _entryUrl(entry) {
  // A piece that has yet to be scanned has no score to name. It opens all the
  // same: what is on the screen then is which piece it is and which collection
  // it is in.
  const search = new URLSearchParams({
    collection: draft.id,
    entry: entry.id,
  });
  if (entry.score_id != null) {
    search.set('id', entry.score_id);
  }
  // Straight to the music. Opening a piece of a collection is opening it to
  // play it, not to read who wrote it.
  return `../scores/perform.html?${search.toString()}`;
}

// ----------------------------------------------------------------------------
// ADDING A SCORE
// ----------------------------------------------------------------------------

function _drawScorePicker() {
  scorePicker.replaceChildren();

  const scores = app.scoreRepository.scores;
  noScoresNotice.hidden = scores.length > 0;

  const needle = forSearch(scoreFilter.value.trim());
  const matching = scores
    .filter((score) => needle === '' || _searchTextOf(score).includes(needle))
    .sort((a, b) => getScoreTitle(a).localeCompare(getScoreTitle(b)));

  for (const score of matching) {
    scorePicker.appendChild(_buildScoreOption(score));
  }
}

/**
 * @param score {Object}
 * @return {HTMLElement}
 */
function _buildScoreOption(score) {
  const option = document.createElement('button');
  option.type = 'button';
  option.className = 'score-option';
  option.innerText = getScoreTitle(score);

  // The same words the collection shows and the same words the list of scores
  // shows. Choosing a piece out of a hundred is the moment those words are
  // worth the most: two of them are called Wiegenlied, and only one is the one
  // for two voices.
  option.append(...buildScoreDetails(score));

  // A collection holds a piece once, so a score that is already in it is said
  // to be rather than offered again. It stays a button: what it does is take
  // the player to the piece, which is what they were asking for.
  const alreadyIn = _entries().find((entry) => entry.score_id === score.id);
  if (alreadyIn != null) {
    option.classList.add('score-option--already-in');
    const chip = document.createElement('span');
    chip.className = 'score-option-state';
    chip.innerText = 'already in this collection';
    option.appendChild(chip);
    option.addEventListener('click', () => _pointAtEntry(alreadyIn.id));
    return option;
  }

  option.addEventListener('click', () => _writeEntry({score_id: score.id}));
  return option;
}

/**
 * Puts a piece into the collection that this app has no score of.
 *
 * What was typed is what it is called, and it is all it will ever be called
 * until somebody scans it, so an empty box adds nothing: the button is off
 * until there is a name, and the cursor stays in the box afterwards, since
 * filling a book in is typing one line after another.
 */
async function onAddPaperEntryClicked() {
  const description = paperEntryInput.value.trim();
  if (description === '') {
    paperEntryInput.focus();
    return;
  }

  paperEntryInput.value = '';
  _syncAddPaperEntryButton();
  await _writeEntry({score_id: null, description: description});
  paperEntryInput.focus();
}

/** There is nothing to add until the piece has a name. */
function _syncAddPaperEntryButton() {
  addPaperEntryButton.disabled = paperEntryInput.value.trim() === '';
}

/**
 * @param score {Object}
 * @return {string}
 */
function _searchTextOf(score) {
  return forSearch([
    getScoreTitle(score),
    _creatorsOf(score),
    ...(score.tags ?? []),
  ].join(' '));
}

/**
 * @param score {Object}
 * @return {string}
 */
function _creatorsOf(score) {
  return [...(score.creators?.composers ?? []), ...(score.creators?.lyricists ?? [])].join(', ');
}

// ----------------------------------------------------------------------------
// SAVING
// ----------------------------------------------------------------------------

async function _save() {
  draft.title = titleInput.value;
  draft.description = descriptionInput.value;
  draft.shared_with = sharedWithInput.value
    .split(/[\n,;]/)
    .map((address) => address.trim())
    .filter((address) => address !== '');

  saveButton.disabled = true;
  try {
    const saved = await app.collectionRepository.saveCollection(draft);
    _readDraftFrom(saved, saved.id);
    _draw();
  } catch (error) {
    console.error('failed to save the collection', error);
    alert(`The collection could not be saved: ${error}`);
    saveButton.disabled = false;
  }
}

async function _delete() {
  if (!confirm('Delete this collection? The scores in it stay where they are.')) {
    return;
  }

  try {
    await app.collectionRepository.deleteCollection(draft.id);
    dirty = false;
    window.location = './';
  } catch (error) {
    console.error('failed to delete the collection', error);
    alert(`The collection could not be deleted: ${error}`);
  }
}

// ----------------------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------------------

/**
 * @param semitones {*}
 * @return {number}
 */
function _transpositionOf(semitones) {
  const asNumber = Number(semitones);
  if (!Number.isFinite(asNumber)) {
    return 0;
  }
  return Math.min(MAX_TRANSPOSITION, Math.max(MIN_TRANSPOSITION, Math.round(asNumber)));
}

/**
 * @param label {string}
 * @param title {string}
 * @param disabled {boolean}
 * @param onClick {function()}
 * @return {HTMLElement}
 */
function _button(label, title, disabled, onClick) {
  const button = document.createElement('button');
  button.type = 'button';
  button.innerText = label;
  button.title = title;
  button.disabled = disabled;
  button.addEventListener('click', onClick);
  return button;
}

async function main() {
  // Fetched but never taken while this page is open: a collection is written as
  // it is changed, and a reload in the middle of that is an edit nobody typed
  // twice. The newer app is there the next time a page is opened.
  keepAppUpToDate()
    .catch((error) => console.error('failed to watch for a newer app', error));

  await app.initialize();

  if (app.user?.isScoreViewer !== true) {
    forbiddenNotice.hidden = false;
    console.log('no score viewer');
    return;
  }
  collectionDetail.hidden = false;

  const collectionId = new URLSearchParams(window.location.search).get('id');

  // A collection this device has is drawn from what it has, network or no
  // network. One it has never heard of is asked about first: a link into a
  // collection can be followed on a device that has not synced since it was
  // shared, and drawing an empty one to type over would be a lie about what is
  // stored under that id.
  const knownHere = collectionId == null
    || app.collectionRepository.getCollection(collectionId) != null;
  if (!knownHere) {
    try {
      await app.updateCollections();
    } catch (error) {
      console.error('failed to sync the collections', error);
    }
  }

  _readDraftFrom(
    collectionId == null ? null : app.collectionRepository.getCollection(collectionId),
    collectionId);
  _draw();

  titleInput.addEventListener('input', () => {
    draft.title = titleInput.value;
    _markDirty();
  });
  descriptionInput.addEventListener('input', () => {
    draft.description = descriptionInput.value;
    _markDirty();
  });
  sharedWithInput.addEventListener('input', _markDirty);
  scoreFilter.addEventListener('input', _drawScorePicker);
  paperEntryInput.addEventListener('input', _syncAddPaperEntryButton);
  _syncAddPaperEntryButton();
  addPaperEntryButton.addEventListener('click', onAddPaperEntryClicked);
  // Typing the name of a piece and pressing enter is how a list like this is
  // filled in; reaching for the button every time is not.
  paperEntryInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      onAddPaperEntryClicked();
    }
  });
  saveButton.addEventListener('click', _save);
  deleteButton.addEventListener('click', _delete);

  // A sync can bring in pieces somebody else added. Redrawing while a control
  // of one has the caret would take the caret away, and the only controls that
  // hold one are the ones being typed into right now.
  app.collectionRepository.addCollectionsChangesListener(() => {
    if (entriesList.contains(document.activeElement)) {
      return;
    }
    _drawEntries();
    _drawScorePicker();
    _drawState();
  });

  // Giving up on an edit is the one thing this app does behind the player's
  // back, so it says so when it happens.
  app.collectionRepository.addSyncProblemListener((problem) => {
    alert(`"${problem.title || 'A collection'}" could not be saved on the server`
      + ` (${problem.action}), and the change has been taken back:`
      + ` ${problem.error.problem?.detail ?? problem.error.message}`);
    if (problem.collectionId === draft.id && !dirty) {
      _readDraftFrom(app.collectionRepository.getCollection(draft.id), draft.id);
      _draw();
    }
  });

  // What is in the collection is stored as it is changed, so the only thing
  // leaving the page could lose is what has been typed into the collection
  // itself.
  window.addEventListener('beforeunload', (event) => {
    if (!dirty) {
      return;
    }
    event.preventDefault();
    event.returnValue = '';
  });

  try {
    await app.updateScores();
    if (knownHere) {
      await app.updateCollections();
    }
  } catch (error) {
    console.error('failed to sync', error);
  }

  // The syncs may have brought in scores this collection names and, when
  // nothing was being typed, a newer version of the collection itself.
  if (!dirty) {
    _readDraftFrom(app.collectionRepository.getCollection(draft.id), draft.id);
  }
  _draw();
}

await main();

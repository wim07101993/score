import {App} from "../app.js";
import {forSearch, getScoreTitle} from "../data/helper-functions.js";
import {MAX_TRANSPOSITION, MIN_TRANSPOSITION} from "../domains/scores/score-view.js";

const setState = document.getElementById('set-state');
const saveButton = document.getElementById('save-button');
const setDetail = document.getElementById('set-detail');
const forbiddenNotice = document.getElementById('forbidden-notice');

const titleInput = document.getElementById('title-input');
const descriptionInput = document.getElementById('description-input');
const sharedWithInput = document.getElementById('shared-with-input');

const entriesList = document.getElementById('entries-list');
const noEntriesNotice = document.getElementById('no-entries-notice');
const unsavedSetNotice = document.getElementById('unsaved-set-notice');

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
 * What the set is, as it is being typed: the gig, and who may read it. It is not
 * stored until the save button says so.
 *
 * What is played in the set is not here. An entry is written on its own, so
 * adding a song, taking one out, moving one and changing its note or key each
 * land as they are made — there is nothing to save afterwards, and nothing to
 * lose by leaving the page. What is drawn for them is read from the set as it
 * is stored, never from here.
 *
 * @type {{id: string, title: string, description: string, shared_with: string[]}}
 */
let draft;

/** Whether the draft says something the stored set does not. @type {boolean} */
let dirty = false;

/** Whether this set is this user's to change. @type {boolean} */
let isOwner = true;

/**
 * Whether the set is stored at all. A set that is not is one there is nothing
 * to put a song into yet: the running order hangs off a set, and the set has to
 * exist first.
 */
let isStored = false;

// ----------------------------------------------------------------------------
// THE SET AS A WHOLE
// ----------------------------------------------------------------------------

/**
 * @param set {import('../domains/sets/database.js').ScoreSet|null}
 * @param setId {string|null}
 */
function _readDraftFrom(set, setId) {
  draft = {
    id: set?.id ?? setId ?? crypto.randomUUID(),
    title: set?.title ?? '',
    description: set?.description ?? '',
    shared_with: [...(set?.shared_with ?? [])],
  };
  isOwner = set == null || set.is_owner !== false;
  isStored = set != null;
  dirty = false;
}

/** The set as it is stored, which is where the running order is read from. */
function _stored() {
  return app.setRepository.getSet(draft.id);
}

/** @return {import('../domains/sets/database.js').SetEntry[]} */
function _entries() {
  return _stored()?.entries ?? [];
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
    // Not read-only: the running order is theirs, but how you read it is yours.
    setState.innerText = owed
      ? 'shared with you — your own reading of it is not sent yet'
      : 'shared with you';
  } else if (dirty) {
    setState.innerText = 'not saved';
  } else if (stored == null) {
    setState.innerText = 'new set';
  } else if (owed) {
    setState.innerText = 'saved here, not sent yet';
  } else {
    setState.innerText = 'saved';
  }

  saveButton.disabled = !isOwner || !dirty;
  saveButton.hidden = !isOwner;
  deleteSection.hidden = !isOwner || !isStored;
  sharingSection.hidden = !isOwner;
  addScoreSection.hidden = !isOwner || !isStored;
  unsavedSetNotice.hidden = isStored || !isOwner;

  // Whose the set is, is something a sync can change its mind about, so this is
  // drawn from the set rather than settled once when the page is opened.
  titleInput.disabled = !isOwner;
  descriptionInput.disabled = !isOwner;
  sharedWithInput.disabled = !isOwner;
}

/**
 * Something was typed into what the set is. That is the only thing here that
 * waits for a save button, and the only thing leaving the page could lose.
 */
function _markDirty() {
  dirty = true;
  _drawState();
}

// ----------------------------------------------------------------------------
// THE SCORES THAT ARE PLAYED
// ----------------------------------------------------------------------------

function _drawEntries() {
  const entries = _entries();
  const typing = _fieldBeingTypedIn();

  entriesList.replaceChildren();
  noEntriesNotice.hidden = entries.length > 0 || !isStored;

  entries.forEach((entry, index) => {
    const item = document.createElement('li');
    item.appendChild(_buildEntry(entry, index, entries.length));
    entriesList.appendChild(item);
  });

  _goOnTypingIn(typing);
}

/**
 * Which box the player is typing in, so that it can be found again in the list
 * that is about to replace this one.
 *
 * Every song of a set is written as it is changed, and a write draws the list
 * afresh — so clicking out of one song's note and straight into the next one's
 * writes the first, throws away every box on the page, and leaves the cursor in
 * a box that no longer exists. Which song and which of its boxes it was, is
 * what survives that; where the boxes happen to be in the list is not, since a
 * write can move them.
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
 * A box that is no longer there — its song was taken out of the set, or the
 * button it was on has become one there is nothing to do with — is left alone
 * rather than guessed at.
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
 * @param entry {import('../domains/sets/database.js').SetEntry}
 * @param index {number}
 * @param count {number}
 * @return {HTMLElement}
 */
function _buildEntry(entry, index, count) {
  const container = document.createElement('div');
  container.className = 'entry';
  // Which song this is, so that the box somebody is typing in can be found
  // again after the list has been drawn afresh.
  container.dataset.entryId = entry.id;

  const score = entry.score_id == null
    ? null
    : app.scoreRepository.scores.find((candidate) => candidate.id === entry.score_id);
  const title = document.createElement('span');
  title.className = 'entry-title';
  if (entry.score_id == null) {
    // A song that is played from paper. It has no score to take a title from,
    // so it is called by what is written next to it — and a song nobody has
    // written anything next to yet is still a song in the gig.
    title.classList.add('entry-on-paper');
    const written = `${entry.description ?? ''}`.trim();
    title.innerText = written === '' ? 'A song, played from paper' : written;
    title.title = 'Played from paper; there is no score here to open.';
  } else if (score == null) {
    title.classList.add('entry-missing');
    title.innerText = 'Not on this device yet';
    title.title = entry.score_id;
  } else {
    title.innerText = getScoreTitle(score);
  }

  container.append(
    title,
    _buildEntryButtons(entry, index, count),
    _buildEntryControls(entry));
  return container;
}

/**
 * @param entry {import('../domains/sets/database.js').SetEntry}
 * @param index {number}
 * @param count {number}
 * @return {HTMLElement}
 */
function _buildEntryButtons(entry, index, count) {
  const buttons = document.createElement('span');
  buttons.className = 'entry-buttons';

  const open = document.createElement('a');
  open.className = 'entry-open';
  open.innerText = 'open';
  open.href = _entryUrl(index);
  buttons.appendChild(open);

  if (!isOwner) {
    return buttons;
  }

  // Moving a song is writing that one song, at the place it moves to; the set
  // is closed up around it.
  buttons.appendChild(_button('↑', 'Move up', index === 0,
    () => _writeEntry({id: entry.id, position: index - 1})));
  buttons.appendChild(_button('↓', 'Move down', index === count - 1,
    () => _writeEntry({id: entry.id, position: index + 1})));
  buttons.appendChild(_button('✕', 'Take out of the set', false, async () => {
    try {
      await app.setRepository.deleteEntry(draft.id, entry.id);
    } catch (error) {
      console.error('failed to take the song out of the set', error);
      alert(`That song could not be taken out of the set: ${error}`);
    }
    _drawEntries();
    _drawState();
  }));
  return buttons;
}

/**
 * @param entry {import('../domains/sets/database.js').SetEntry}
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
  description.placeholder = 'capo 2, second verse only, straight into the next';
  description.disabled = !isOwner;
  // On change rather than on input: every one of these is a write of that song,
  // and a write per keystroke is a write per keystroke.
  description.addEventListener('change', () =>
    _writeEntry({id: entry.id, description: description.value}));

  controls.append(description, _buildTransposition(entry), _buildParts(entry));
  return controls;
}

/**
 * How far the song is read from where it is written, which is two numbers and
 * not one: the key the band plays it in, and how far this player reads it from
 * there. They are shown in the order they add, with the sum spelled out — on
 * their own they are a pair of bare boxes, and nobody should have to work out
 * that the second is counted on top of the first or that either is semitones.
 *
 * The player's half is written on its own rather than with the set: a view says
 * nothing about the set and changes nothing anybody else sees, so everyone the
 * set is shared with can set their own — a player who cannot change a note of
 * the running order still reads it in the key their instrument is in.
 *
 * @param entry {import('../domains/sets/database.js').SetEntry}
 * @return {HTMLElement}
 */
function _buildTransposition(entry) {
  const group = document.createElement('span');
  group.className = 'entry-transpose';
  group.appendChild(document.createTextNode('transpose'));

  // What the band does, which is the owner's to say and the same for everyone.
  const band = _numberInput(entry.transposition, !isOwner, 'band', (semitones) =>
    _writeEntry({id: entry.id, transposition: semitones}));
  group.appendChild(_transpositionField('band', band,
    'The key the band plays this one in, counted in semitones from where it is written. Everyone sees this.'));

  const plus = document.createElement('span');
  plus.className = 'entry-transpose-plus';
  plus.innerText = '+';
  group.appendChild(plus);

  // What this player does on top of it, which is theirs and nobody else's.
  const mine = _numberInput(entry.view.transposition, false, 'me', (semitones) =>
    _saveMyView(entry.id, {transposition: semitones, hidden_parts: entry.view.hidden_parts}));
  group.appendChild(_transpositionField('me', mine,
    'How far you read it on top of the band, again in semitones. Only you see this.'));

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
 * The two are added rather than one replacing the other, and the sum is held to
 * the range the score offers — so a pair that adds up past an octave is shown
 * at the edge it will really be read at rather than at a number nothing can
 * play.
 *
 * @param entry {import('../domains/sets/database.js').SetEntry}
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
 * Which parts of the song this player has off their screen, which is theirs and
 * nobody else's in the same way the key they read it in is.
 *
 * @param entry {import('../domains/sets/database.js').SetEntry}
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
 * Writes one song of the set. Everything about an entry is written as it is
 * changed rather than waiting for a save button: an entry is a resource of its
 * own, so there is nothing it has to be saved along with.
 *
 * @param entry {{id?: string, score_id?: string|null, description?: string,
 *   transposition?: number, position?: number}}
 * @return {Promise<void>}
 */
async function _writeEntry(entry) {
  try {
    await app.setRepository.saveEntry(draft.id, entry);
  } catch (error) {
    console.error('failed to write the song into the set', error);
    alert(`That song could not be written into the set: ${error}`);
  }
  _drawEntries();
  _drawState();
}

/**
 * Stores how this player reads one entry.
 *
 * A view is written whole rather than a field at a time, so what the caller has
 * not said is filled in from how the entry is read now. Saying only that the
 * key has changed is not saying to read the song at the size every other one is
 * drawn at, or to put the parts that are off screen back on it.
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
    await app.setRepository.saveEntryView(draft.id, entryId, whole);
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
 * Where an entry is played from. An entry is pointed at by its id, which stays
 * that entry's for as long as it is in the set — where it comes in the running
 * order does not, and a link is read long after it was made.
 *
 * @param index {number}
 * @return {string}
 */
function _entryUrl(index) {
  const entry = _entries()[index];
  // A song that is played from paper has no score to name. It opens all the
  // same: what is on the screen then is which song it is and where in the gig
  // it comes, with the way on to the next one.
  const search = new URLSearchParams({
    set: draft.id,
    entry: entry.id,
  });
  if (entry.score_id != null) {
    search.set('id', entry.score_id);
  }
  // Straight to the music. Opening a song of a gig is opening it to play it,
  // not to read who wrote it.
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

  const creators = _creatorsOf(score);
  if (creators !== '') {
    const line = document.createElement('span');
    line.className = 'score-option-creators';
    line.innerText = creators;
    option.appendChild(line);
  }

  // The same score can be played more than once in a gig, each time with its
  // own key and its own note next to it, so this adds rather than toggles. It
  // goes at the end, which is where a song being added to a gig goes.
  option.addEventListener('click', () => _writeEntry({score_id: score.id}));

  return option;
}

/**
 * Puts a song into the set that this app has no score of.
 *
 * It goes in at the end, which is where a song being added to a gig goes, and
 * is called by what was typed. Nothing is asked of that text: a blank line in a
 * running order is a thing people write, and the entry can be named later the
 * same way any other is.
 */
async function onAddPaperEntryClicked() {
  const description = paperEntryInput.value.trim();
  paperEntryInput.value = '';
  await _writeEntry({score_id: null, description: description});
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
    const saved = await app.setRepository.saveSet(draft);
    _readDraftFrom(saved, saved.id);
    _draw();
  } catch (error) {
    console.error('failed to save the set', error);
    alert(`The set could not be saved: ${error}`);
    saveButton.disabled = false;
  }
}

async function _delete() {
  if (!confirm('Delete this set? The scores in it stay where they are.')) {
    return;
  }

  try {
    await app.setRepository.deleteSet(draft.id);
    dirty = false;
    window.location = './';
  } catch (error) {
    console.error('failed to delete the set', error);
    alert(`The set could not be deleted: ${error}`);
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
  await app.initialize();

  if (app.user?.isScoreViewer !== true) {
    forbiddenNotice.hidden = false;
    console.log('no score viewer');
    return;
  }
  setDetail.hidden = false;

  const setId = new URLSearchParams(window.location.search).get('id');

  // A set this device has is drawn from what it has, network or no network. One
  // it has never heard of is asked about first: a link into a set can be
  // followed on a device that has not synced since it was shared, and drawing
  // an empty set to type over would be a lie about what is stored under that
  // id.
  const knownHere = setId == null || app.setRepository.getSet(setId) != null;
  if (!knownHere) {
    try {
      await app.updateSets();
    } catch (error) {
      console.error('failed to sync the sets', error);
    }
  }

  _readDraftFrom(setId == null ? null : app.setRepository.getSet(setId), setId);
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
  addPaperEntryButton.addEventListener('click', onAddPaperEntryClicked);
  // Typing the name of a song and pressing enter is how a list like this is
  // filled in; reaching for the button every time is not.
  paperEntryInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      onAddPaperEntryClicked();
    }
  });
  saveButton.addEventListener('click', _save);
  deleteButton.addEventListener('click', _delete);

  // A sync can bring in a running order somebody else changed. Redrawing while
  // a control of it has the caret would take the caret away, and the only
  // controls that hold one are the ones being typed into right now.
  app.setRepository.addSetsChangesListener(() => {
    if (entriesList.contains(document.activeElement)) {
      return;
    }
    _drawEntries();
    _drawState();
  });

  // Giving up on an edit is the one thing this app does behind the player's
  // back, so it says so when it happens.
  app.setRepository.addSyncProblemListener((problem) => {
    alert(`"${problem.title || 'A set'}" could not be saved on the server`
      + ` (${problem.action}), and the change has been taken back:`
      + ` ${problem.error.problem?.detail ?? problem.error.message}`);
    if (problem.setId === draft.id && !dirty) {
      _readDraftFrom(app.setRepository.getSet(draft.id), draft.id);
      _draw();
    }
  });

  // What is played in the set is stored as it is changed, so the only thing
  // leaving the page could lose is what has been typed into the set itself.
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
      await app.updateSets();
    }
  } catch (error) {
    console.error('failed to sync', error);
  }

  // The syncs may have brought in scores this set names and, when nothing was
  // being typed, a newer version of the set itself.
  if (!dirty) {
    _readDraftFrom(app.setRepository.getSet(draft.id), draft.id);
  }
  _draw();
}

await main();

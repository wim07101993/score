import test from 'node:test';
import assert from 'node:assert/strict';

import {getInstrumentName, getLanguageName} from './translations.js';

// ---------------------------------------------------------------------------
// WHAT TO CALL AN INSTRUMENT
// ---------------------------------------------------------------------------

test('an instrument nobody has a word for is called what the document called it', () => {
  assert.equal(getInstrumentName('wind.flutes.flute'), 'flute');
  assert.equal(getInstrumentName('pluck.banjo.tenor'), 'pluck.banjo.tenor');
});

// ---------------------------------------------------------------------------
// WHAT TO CALL A LANGUAGE
// ---------------------------------------------------------------------------

test('a language is named rather than left as the code it is stored as', () => {
  assert.equal(getLanguageName('nl'), 'Dutch');
  assert.equal(getLanguageName('de'), 'German');
  assert.equal(getLanguageName(' en '), 'English');
});

test('a tag nobody can name is shown as it came rather than dropped', () => {
  // Both of these are what a document can actually contain: a tag that is
  // shaped like one but means nothing, and a tag that is not shaped like one at
  // all — which makes the machine throw rather than shrug.
  assert.equal(getLanguageName('qqq'), 'qqq');
  assert.equal(getLanguageName('not a language'), 'not a language');
});

test('a score with nothing said about its language says nothing', () => {
  assert.equal(getLanguageName(''), '');
  assert.equal(getLanguageName('   '), '');
  assert.equal(getLanguageName(null), '');
  assert.equal(getLanguageName(undefined), '');
});

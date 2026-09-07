import test from 'node:test';
import assert from 'node:assert/strict';

import {forSearch, getScoreTitle, scoreMatches} from './helper-functions.js';

// ---------------------------------------------------------------------------
// WHAT TO CALL A SCORE
// ---------------------------------------------------------------------------

test('a score is titled by its work, and by its movement when the work has no title', () => {
  assert.equal(getScoreTitle({work: {title: 'Requiem'}, movement: {title: 'Pie Jesu'}}), 'Requiem');
  assert.equal(getScoreTitle({movement: {title: 'Pie Jesu'}}), 'Pie Jesu');
});

test('a score that names neither is an untitled score', () => {
  assert.equal(getScoreTitle({}), 'Untitled score');
  assert.equal(getScoreTitle(null), 'Untitled score');
  assert.equal(getScoreTitle({work: {title: '   '}}), 'Untitled score');
});

// ---------------------------------------------------------------------------
// SEARCHING
// ---------------------------------------------------------------------------

test('searching does not care about accents', () => {
  assert.equal(forSearch('Après un rêve'), 'apres un reve');
  assert.equal(forSearch('Fauré'), 'faure');
  assert.equal(forSearch('Dvořák'), 'dvorak');
});

test('what was typed and what was uploaded are compared the same way', () => {
  assert.ok(forSearch('Après un rêve').includes(forSearch('apres')));
  assert.ok(forSearch('Apres un reve').includes(forSearch('Après')));
});

test('searching does not care about case', () => {
  assert.equal(forSearch('MOZART'), 'mozart');
});

test('a letter that is not an accented one is left alone', () => {
  assert.equal(forSearch('Ø'), 'ø');
});

test('nothing to search is nothing to search for', () => {
  assert.equal(forSearch(null), '');
  assert.equal(forSearch(undefined), '');
  assert.equal(forSearch(''), '');
});

// ----------------------------------------------------------------------------
// LOOKING FOR ONE SCORE
// ----------------------------------------------------------------------------

/** @param overrides {Object} */
function aScore(overrides = {}) {
  return {
    work: {title: 'An die ferne Geliebte', number: 'Op. 98'},
    movement: {title: '', number: ''},
    creators: {composers: ['Ludwig van Beethoven'], lyricists: ['Aloys Jeitteles']},
    instruments: ['voice.vocals', 'keyboard.piano'],
    tags: ['christmas'],
    ...overrides,
  };
}

test('a score is found by its title, its creators, its instruments and its tags', () => {
  const score = aScore();

  assert.equal(scoreMatches(score, 'ferne'), true, 'by its title');
  assert.equal(scoreMatches(score, 'beethoven'), true, 'by its composer');
  assert.equal(scoreMatches(score, 'jeitteles'), true, 'by its lyricist');
  assert.equal(scoreMatches(score, 'christmas'), true, 'by what it is filed under');
});

// The instruments are stored as the words MusicXML uses and shown as the words
// a musician uses. What is on the screen is what is being searched.
test('a score is found by the name of its instrument, not by its sound id', () => {
  assert.equal(scoreMatches(aScore(), 'piano'), true);
  assert.equal(scoreMatches(aScore(), 'keyboard.piano'), false);
});

// Somebody searching a library types what they remember about a piece, and
// what they remember is rarely one field of it in the order it is written.
test('every word has to be found, and each of them anywhere', () => {
  assert.equal(scoreMatches(aScore(), 'beethoven ferne'), true);
  assert.equal(scoreMatches(aScore(), 'beethoven brahms'), false);
});

test('searching for a score does not care about accents or case', () => {
  const score = aScore({work: {title: 'Après un rêve', number: ''}});

  assert.equal(scoreMatches(score, 'apres'), true);
  assert.equal(scoreMatches(score, 'APRÈS'), true);
});

test('nothing typed is not a search, and every score is in it', () => {
  assert.equal(scoreMatches(aScore(), ''), true);
  assert.equal(scoreMatches(aScore(), '   '), true);
  assert.equal(scoreMatches(aScore(), null), true);
});

// A score this device has just been told about has nothing but an id yet, and
// a search box is no place to find that out.
test('a score that says nothing about itself is searched without dying', () => {
  const bare = {id: 'a-score'};

  assert.equal(scoreMatches(bare, ''), true);
  assert.equal(scoreMatches(bare, 'beethoven'), false);
  assert.equal(scoreMatches(bare, 'untitled'), true);
});

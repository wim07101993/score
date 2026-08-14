import test from 'node:test';
import assert from 'node:assert/strict';

import {forSearch, getScoreTitle} from './helper-functions.js';

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

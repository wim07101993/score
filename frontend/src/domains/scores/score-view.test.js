import test from 'node:test';
import assert from 'node:assert/strict';

import {MAX_TRANSPOSITION, MIN_TRANSPOSITION, ScoreView} from './score-view.js';

const PARTS = ['P1', 'P2', 'P3'];

test('a score opens with every part on screen and written as it was written', () => {
  const view = ScoreView.forParts(PARTS);

  assert.equal(view.transposition, 0);
  assert.deepEqual(view.visiblePartIds, PARTS);
  assert.deepEqual(view.hiddenPartIds, []);
  assert.ok(view.isPristine);
});

// ---------------------------------------------------------------------------
// TRANSPOSING
// ---------------------------------------------------------------------------

test('a score can be transposed up and down', () => {
  const view = ScoreView.forParts(PARTS);

  assert.equal(view.withTransposition(3).transposition, 3);
  assert.equal(view.withTransposition(-5).transposition, -5);
});

test('transposing further than an octave stops at an octave', () => {
  const view = ScoreView.forParts(PARTS);

  assert.equal(view.withTransposition(99).transposition, MAX_TRANSPOSITION);
  assert.equal(view.withTransposition(-99).transposition, MIN_TRANSPOSITION);
});

test('a transposition is a whole number of semitones', () => {
  const view = ScoreView.forParts(PARTS);

  assert.equal(view.withTransposition(2.4).transposition, 2);
  assert.equal(view.withTransposition(-2.6).transposition, -3);
});

test('something that is not a number is not a transposition', () => {
  const view = ScoreView.forParts(PARTS).withTransposition(4);

  for (const notANumber of [NaN, Infinity, -Infinity, null, undefined, '5', {}]) {
    assert.equal(view.withTransposition(notANumber).transposition, 4,
      `${String(notANumber)} should have left the transposition alone`);
  }
});

test('a transposed score is no longer pristine', () => {
  assert.equal(ScoreView.forParts(PARTS).withTransposition(1).isPristine, false);
  assert.equal(ScoreView.forParts(PARTS).withTransposition(0).isPristine, true);
});

// ---------------------------------------------------------------------------
// HIDING PARTS
// ---------------------------------------------------------------------------

test('a part can be taken off the screen and put back', () => {
  const view = ScoreView.forParts(PARTS);

  const hidden = view.withPartVisible('P2', false);
  assert.ok(hidden.isHidden('P2'));
  assert.deepEqual(hidden.visiblePartIds, ['P1', 'P3']);

  const shown = hidden.withPartVisible('P2', true);
  assert.equal(shown.isHidden('P2'), false);
  assert.deepEqual(shown.visiblePartIds, PARTS);
});

test('the parts left on screen keep the order the score lists them in', () => {
  const view = ScoreView.forParts(PARTS)
    .withPartVisible('P1', false)
    .withPartVisible('P1', true);

  assert.deepEqual(view.visiblePartIds, ['P1', 'P2', 'P3']);
});

// A score with nothing on it is not a view of anything, and there would be no
// part left in the controls to click to get back.
test('the last part on screen cannot be taken off it', () => {
  const oneLeft = ScoreView.forParts(PARTS)
    .withPartVisible('P1', false)
    .withPartVisible('P2', false);
  assert.deepEqual(oneLeft.visiblePartIds, ['P3']);

  const stillOneLeft = oneLeft.withPartVisible('P3', false);

  assert.deepEqual(stillOneLeft.visiblePartIds, ['P3'], 'the score was left with no parts at all');
  assert.equal(stillOneLeft, oneLeft, 'a refused change should hand back the view unchanged');
});

test('a part the score does not have is not a part', () => {
  const view = ScoreView.forParts(PARTS);

  const unchanged = view.withPartVisible('not-a-part', false);

  assert.equal(unchanged, view);
  assert.deepEqual(unchanged.visiblePartIds, PARTS);
});

test('hiding a part that is already hidden changes nothing', () => {
  const view = ScoreView.forParts(PARTS).withPartVisible('P2', false);

  assert.equal(view.withPartVisible('P2', false), view);
  assert.deepEqual(view.hiddenPartIds, ['P2'], 'the part was hidden twice over');
});

test('a score with a hidden part is no longer pristine', () => {
  assert.equal(ScoreView.forParts(PARTS).withPartVisible('P2', false).isPristine, false);
});

// ---------------------------------------------------------------------------
// IMMUTABILITY
// ---------------------------------------------------------------------------

// The score itself is immutable, and so is the way of looking at it: a change
// hands back a new view and leaves the one the caller is holding alone, so
// going back to how the score was written is a matter of keeping the old view.
test('changing a view leaves the view it was made from alone', () => {
  const original = ScoreView.forParts(PARTS);

  const changed = original.withTransposition(7).withPartVisible('P1', false);

  assert.equal(original.transposition, 0);
  assert.deepEqual(original.visiblePartIds, PARTS);
  assert.ok(original.isPristine);

  assert.equal(changed.transposition, 7);
  assert.deepEqual(changed.visiblePartIds, ['P2', 'P3']);
});

test('a view cannot be written to', () => {
  const view = ScoreView.forParts(PARTS).withPartVisible('P2', false);

  assert.throws(() => { view._transposition = 5; }, TypeError);
  assert.throws(() => { view.partIds.push('P4'); }, TypeError);
  assert.throws(() => { view.hiddenPartIds.push('P3'); }, TypeError);

  assert.equal(view.transposition, 0);
  assert.deepEqual(view.partIds, PARTS);
  assert.deepEqual(view.hiddenPartIds, ['P2']);
});

test('the list of parts handed in cannot be changed underneath a view', () => {
  const parts = ['P1', 'P2'];
  const view = ScoreView.forParts(parts);

  parts.push('P3');

  assert.deepEqual(view.partIds, ['P1', 'P2']);
});

test('resetting gives back the score as it was written, with the same parts', () => {
  const view = ScoreView.forParts(PARTS)
    .withTransposition(-4)
    .withPartVisible('P3', false);

  const reset = view.reset();

  assert.ok(reset.isPristine);
  assert.deepEqual(reset.partIds, PARTS);
  assert.deepEqual(reset.visiblePartIds, PARTS);
  assert.equal(view.transposition, -4, 'resetting changed the view it was made from');
});

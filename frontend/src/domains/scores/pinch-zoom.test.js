import test from 'node:test';
import assert from 'node:assert/strict';

import {
  clampZoom,
  DEFAULT_ZOOM,
  distanceBetween,
  MAX_ZOOM,
  MIN_ZOOM,
  Pinch,
} from './pinch-zoom.js';

// ---------------------------------------------------------------------------
// HOW BIG THE MUSIC IS
// ---------------------------------------------------------------------------

test('music is drawn the size it is written at until somebody says otherwise', () => {
  assert.equal(clampZoom(DEFAULT_ZOOM), DEFAULT_ZOOM);
});

test('a size past either end of the range stops at the end', () => {
  assert.equal(clampZoom(99), MAX_ZOOM);
  assert.equal(clampZoom(0.01), MIN_ZOOM);
});

test('something that is not a size is the size a score is written at', () => {
  for (const notASize of [NaN, Infinity, -Infinity, null, undefined, '2', {}]) {
    assert.equal(clampZoom(notASize), DEFAULT_ZOOM, `${String(notASize)} is not a size`);
  }
});

// ---------------------------------------------------------------------------
// PINCHING
// ---------------------------------------------------------------------------

test('fingers twice as far apart draw the music twice as big', () => {
  const pinch = Pinch.begin(1, 100);

  assert.equal(pinch.zoomAt(200), 2);
});

test('fingers coming together draw the music smaller', () => {
  const pinch = Pinch.begin(2, 100);

  assert.equal(pinch.zoomAt(50), 1);
});

test('a pinch is measured against where it started rather than against the last reading', () => {
  const pinch = Pinch.begin(1, 100);

  pinch.zoomAt(150);
  pinch.zoomAt(120);

  assert.equal(pinch.zoomAt(100), 1, 'coming back to where it started should undo the pinch');
});

test('a pinch that has run past the range stops there', () => {
  const pinch = Pinch.begin(1, 100);

  assert.equal(pinch.zoomAt(100 * (MAX_ZOOM + 5)), MAX_ZOOM);
  assert.equal(pinch.zoomAt(1), MIN_ZOOM);
});

test('what is shown while pinching is what letting go will draw', () => {
  const pinch = Pinch.begin(2, 100);

  // Halfway through the pinch, and past the end of it: in both cases the music
  // on screen is the size it started at times what it is being stretched by.
  assert.equal(2 * pinch.scaleAt(150), pinch.zoomAt(150));
  assert.equal(2 * pinch.scaleAt(100000), pinch.zoomAt(100000));
  assert.equal(pinch.zoomAt(100000), MAX_ZOOM, 'and it should have stopped at the end');
});

test('a pinch starts from the size the music is already being read at', () => {
  const pinch = Pinch.begin(1.5, 100);

  assert.equal(pinch.zoom, 1.5);
  assert.equal(pinch.zoomAt(100), 1.5, 'fingers that have not moved should change nothing');
});

test('two fingers in the same place are no pinch at all', () => {
  assert.equal(Pinch.begin(1, 0), null);
  assert.equal(Pinch.begin(1, NaN), null);
});

test('fingers that end up in the same place leave the music as it was', () => {
  const pinch = Pinch.begin(1.5, 100);

  assert.equal(pinch.zoomAt(0), 1.5);
});

test('how far apart two fingers are', () => {
  assert.equal(distanceBetween({x: 0, y: 0}, {x: 3, y: 4}), 5);
  assert.equal(distanceBetween({x: 3, y: 4}, {x: 0, y: 0}), 5);
});

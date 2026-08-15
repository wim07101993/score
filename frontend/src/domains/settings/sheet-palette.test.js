import test from 'node:test';
import assert from 'node:assert/strict';

import {
  clampBrightness,
  clampWarmth,
  defaultPageLook,
  DIMMEST,
  FULL,
  greyGiving,
  NIGHT,
  NIGHT_WARMTH,
  SheetPalette,
} from './sheet-palette.js';

test('a page at full is white paper with black ink on it', () => {
  const palette = SheetPalette.lamp(FULL);

  assert.equal(palette.paper, '#ffffff');
  assert.equal(palette.ink, '#000000');
});

// The whole of what "dark" means here. Every version of this that swapped them
// round — light marks on a dark page — was wrong in the same way.
test('a dimmed page is still darker ink on lighter paper', () => {
  const palette = SheetPalette.lamp(NIGHT, NIGHT_WARMTH);

  assert.ok(_lightness(palette.paper) > _lightness(palette.ink),
    `${palette.paper} should be lighter than ${palette.ink}`);
});

// The dial is a share of light, not of the numbers a colour is written with.
// Half way down is the page that throws half the light, which is #bcbcbc and
// nowhere near the halfway #808080.
test('half a page of light is the grey that gives off half the light', () => {
  assert.equal(SheetPalette.lamp(0.5).paper, '#bcbcbc');
});

test('the dimmer the lamp, the darker the paper', () => {
  const lamps = [DIMMEST, 0.29, 0.5, 0.8, FULL];

  const papers = lamps.map((lamp) => _lightness(SheetPalette.lamp(lamp).paper));

  for (let i = 1; i < papers.length; i++) {
    assert.ok(papers[i] > papers[i - 1],
      `a page at ${lamps[i]} should be lighter than one at ${lamps[i - 1]}`);
  }
});

// Two dials that moved each other would be two dials nobody could set.
test('warming a page does not also brighten it', () => {
  const neutral = _lightness(SheetPalette.lamp(0.5).paper);
  const warm = _lightness(SheetPalette.lamp(0.5, 1).paper);

  assert.ok(Math.abs(warm - neutral) < 0.01,
    `warming ${neutral} should not have taken it to ${warm}`);
});

test('a warm page is redder than it is blue', () => {
  const {red, green, blue} = _channels(SheetPalette.lamp(0.5, 1).paper);

  assert.ok(red > green && green > blue, `${red},${green},${blue} is not a warm grey`);
});

test('a grace note is drawn lighter than the note it leans on', () => {
  const palette = SheetPalette.lamp(NIGHT, NIGHT_WARMTH);

  assert.match(palette.fadedInk, /^rgb\(\d+ \d+ \d+ \/ 0\.\d+\)$/);
});

// A page below this cannot hold its ink clear of itself, and a page above full
// is a page that does not exist. Anything that is not a number at all is a
// setting nobody made.
test('a lamp is never turned past either end', () => {
  assert.equal(clampBrightness(0), DIMMEST);
  assert.equal(clampBrightness(4), FULL);
  assert.equal(clampBrightness(NIGHT), NIGHT);
  assert.equal(clampBrightness('bright'), FULL);
  assert.equal(clampBrightness(NaN), FULL);
  assert.equal(clampBrightness(undefined), FULL);
});

test('warmth is never turned past either end', () => {
  assert.equal(clampWarmth(-1), 0);
  assert.equal(clampWarmth(2), 1);
  assert.equal(clampWarmth(0.3), 0.3);
  assert.equal(clampWarmth('warm'), 0);
});

test('a colour is never asked for outside the range a colour has', () => {
  assert.equal(SheetPalette.lamp(DIMMEST, 1).paper.length, 7);
  assert.match(SheetPalette.lamp(DIMMEST, 1).paper, /^#[0-9a-f]{6}$/);
  assert.match(SheetPalette.lamp(FULL, 1).ink, /^#[0-9a-f]{6}$/);
});

test('the lamp starts full in a lit room and turned down in a dark one', () => {
  assert.deepEqual(defaultPageLook('light'), {brightness: FULL, warmth: 0});
  assert.deepEqual(defaultPageLook('dark'), {brightness: NIGHT, warmth: NIGHT_WARMTH});
});

test('white gives off all of the light and black none of it', () => {
  assert.equal(Math.round(greyGiving(1)), 255);
  assert.equal(Math.round(greyGiving(0)), 0);
});

/**
 * Roughly how much light a colour throws, which is all these tests need of it:
 * they compare, they do not measure.
 *
 * @param hex {string}
 * @return {number}
 */
function _lightness(hex) {
  const {red, green, blue} = _channels(hex);
  return (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255;
}

/**
 * @param hex {string}
 * @return {{red: number, green: number, blue: number}}
 */
function _channels(hex) {
  return {
    red: parseInt(hex.slice(1, 3), 16),
    green: parseInt(hex.slice(3, 5), 16),
    blue: parseInt(hex.slice(5, 7), 16),
  };
}

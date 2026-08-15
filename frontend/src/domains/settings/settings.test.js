import test from 'node:test';
import assert from 'node:assert/strict';

import {defaultPageLook, DIMMEST, FULL, NIGHT, NIGHT_WARMTH} from './sheet-palette.js';

// The settings read the localStorage global at call time, so a fake put here
// before importing is enough to drive them. Which way round the machine says it
// is, is a media query, and is faked the same way.
const store = new Map();
globalThis.localStorage = {
  setItem: (key, value) => store.set(key, String(value)),
  getItem: (key) => (store.has(key) ? store.get(key) : null),
  removeItem: (key) => store.delete(key),
};

let machineIsDark = false;
globalThis.matchMedia = (query) => ({
  matches: query.includes('dark') && machineIsDark,
  addEventListener: () => undefined,
});

const {Settings, themeModeStorageKey} = await import('./settings.js');

test.beforeEach(() => {
  store.clear();
  machineIsDark = false;
});

test('a device that has never been asked follows the machine', () => {
  assert.equal(Settings.themeMode, 'system');
});

test('a way round survives a round trip', () => {
  Settings.themeMode = 'dark';

  assert.equal(Settings.themeMode, 'dark');
});

// Following the system is what an app does when it has been told nothing, so it
// is stored as nothing: a device that has never been asked and one that has
// been put back to following the machine are the same device.
test('going back to following the machine leaves nothing behind', () => {
  Settings.themeMode = 'dark';

  Settings.themeMode = 'system';

  assert.equal(store.get(themeModeStorageKey), undefined);
  assert.equal(Settings.themeMode, 'system');
});

// A key from a version that wrote them differently is not worth a page that
// will not start.
test('a way round nobody can read follows the machine', () => {
  store.set(themeModeStorageKey, 'sepia');

  assert.equal(Settings.themeMode, 'system');
});

test('what is on the screen is what was chosen, whatever the machine says', () => {
  machineIsDark = true;
  Settings.themeMode = 'light';

  assert.equal(Settings.brightness, 'light');
});

test('what is on the screen is what the machine says when nothing was chosen', () => {
  machineIsDark = true;

  assert.equal(Settings.brightness, 'dark');

  machineIsDark = false;

  assert.equal(Settings.brightness, 'light');
});

test('an untouched page is the one nobody has set', () => {
  assert.deepEqual(Settings.pageLook('light'), defaultPageLook('light'));
  assert.deepEqual(Settings.pageLook('dark'), defaultPageLook('dark'));
  assert.ok(Settings.isPageLookDefault('dark'));
});

test('a page survives a round trip', () => {
  Settings.setPageLook('dark', {brightness: 0.4, warmth: 0.5});

  assert.deepEqual(Settings.pageLook('dark'), {brightness: 0.4, warmth: 0.5});
  assert.ok(!Settings.isPageLookDefault('dark'));
});

// Two different rooms: the lamp a reader wants at a lit desk is not the one
// they want at a gig, and setting one must not set the other.
test('the light page and the dark page are set apart from one another', () => {
  Settings.setPageLook('dark', {brightness: 0.4, warmth: 0.5});

  assert.deepEqual(Settings.pageLook('light'), defaultPageLook('light'));
});

test('a page set past either end is held at the end', () => {
  Settings.setPageLook('dark', {brightness: 0, warmth: 3});

  assert.deepEqual(Settings.pageLook('dark'), {brightness: DIMMEST, warmth: 1});
});

test('putting a page back leaves nothing behind', () => {
  Settings.setPageLook('dark', {brightness: 0.4, warmth: 0.5});

  Settings.resetPageLook('dark');

  assert.equal(store.get('score-page-look-dark'), undefined);
  assert.deepEqual(Settings.pageLook('dark'), {brightness: NIGHT, warmth: NIGHT_WARMTH});
  assert.ok(Settings.isPageLookDefault('dark'));
});

// Half of a pair of numbers, or none, is the page nobody has touched rather
// than a page that cannot be drawn.
test('a page nobody can read is the page nobody has touched', () => {
  for (const stored of ['', '0.4', 'a,b', '0.4,0.5,0.6', 'null']) {
    store.set('score-page-look-light', stored);

    assert.deepEqual(Settings.pageLook('light'), {brightness: FULL, warmth: 0},
      `"${stored}" should have read as an untouched page`);
  }
});

test('the palette that is applied is the one for the room the app is in', () => {
  machineIsDark = true;
  Settings.setPageLook('dark', {brightness: FULL, warmth: 0});

  assert.equal(Settings.sheetPalette.paper, '#ffffff');
});

test('applying puts the way round and the page on the document', () => {
  Settings.themeMode = 'dark';
  Settings.setPageLook('dark', {brightness: FULL, warmth: 0});
  const root = _fakeRoot();

  Settings.apply(root);

  assert.equal(root.attributes.get('data-theme'), 'dark');
  assert.equal(root.style.properties.get('--paper'), '#ffffff');
  assert.equal(root.style.properties.get('--ink'), '#000000');
});

test('following the machine is said by saying nothing', () => {
  const root = _fakeRoot();
  root.attributes.set('data-theme', 'dark');
  Settings.themeMode = 'system';

  Settings.apply(root);

  assert.equal(root.attributes.has('data-theme'), false);
});

/**
 * As much of an element as applying the settings touches.
 */
function _fakeRoot() {
  const attributes = new Map();
  const properties = new Map();
  return {
    attributes,
    style: {properties, setProperty: (name, value) => properties.set(name, value)},
    setAttribute: (name, value) => attributes.set(name, value),
    removeAttribute: (name) => attributes.delete(name),
  };
}

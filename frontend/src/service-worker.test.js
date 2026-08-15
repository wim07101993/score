import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync, readdirSync} from 'node:fs';
import path from 'node:path';

/**
 * That the app works with no network at all rests entirely on one hand-written
 * list, and a list is a thing that goes out of date quietly: a file added and
 * not listed is a file that works all the way through development and every
 * test, and is missing at the one moment it was needed — on a stand, in a room
 * with no signal, in front of people.
 *
 * So the list is checked against what is actually served.
 */

const src = import.meta.dirname;

/**
 * The worker reaches for `self` the moment it is read, so it cannot be
 * imported here. The list is a literal array of strings and reading it out of
 * the source is the plainest way to ask what is in it.
 *
 * @return {string[]}
 */
function precachedUrls() {
  const source = readFileSync(path.join(src, 'service-worker.js'), 'utf8');
  const list = source.split('const cacheUrls = [')[1]?.split('];')[0];
  assert.ok(list, 'the worker no longer has a cacheUrls array to read');
  return [...list.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
}

/**
 * A file that is served but that nothing ever asks for, and why.
 *
 * @type {Object<string, string>}
 */
const notAskedFor = {
  // Moved over config.json by the release workflow, and the other one deleted.
  '/config.dev.json': 'a release input, not a file the app fetches',
  '/config.prod.json': 'a release input, not a file the app fetches',
  // It ships, since the whole of src/ does, but nothing loads it.
  '/service-worker.test.js': 'a test',
};

/**
 * A directory is listed by the url a page is actually asked for, never as
 * "<dir>/index.html": the file server answers that spelling with a redirect,
 * and a redirect is not something that can be cached.
 *
 * @type {Object<string, string>}
 */
const askedForAs = {
  '/index.html': '/',
  '/sets/index.html': '/sets/',
};

/** @return {string[]} every file under src/, as the url it is served at */
function servedFiles(directory = src, prefix = '') {
  const served = [];
  for (const entry of readdirSync(directory, {withFileTypes: true})) {
    if (entry.name.startsWith('.')) {
      continue;
    }
    if (entry.isDirectory()) {
      served.push(...servedFiles(path.join(directory, entry.name), `${prefix}/${entry.name}`));
      continue;
    }
    if (entry.name.endsWith('.test.js') || entry.name === 'service-worker.js') {
      continue;
    }
    served.push(`${prefix}/${entry.name}`);
  }
  return served;
}

// The one that matters: a page or a module that was added and not listed.
test('every file the app is built out of is cached', () => {
  const precached = new Set(precachedUrls());

  const missing = servedFiles()
    .filter((url) => notAskedFor[url] == null)
    .filter((url) => !precached.has(url) && !precached.has(askedForAs[url]));

  assert.deepEqual(missing, [],
    'these are served but would not be there without a network');
});

// The other way round is a worker that cannot install: one url that answers
// 404 is one file of the app that no device gets.
test('nothing is cached that is not there to be cached', () => {
  const served = new Set(servedFiles().map((url) => askedForAs[url] ?? url));

  const gone = precachedUrls().filter((url) => !served.has(url));

  assert.deepEqual(gone, [], 'these are listed but are not files any more');
});

test('no file is listed twice', () => {
  const urls = precachedUrls();

  assert.equal(new Set(urls).size, urls.length);
});

// Every page of the app, by name, so that dropping one out of the list is a
// decision somebody has to make here rather than a line that quietly went
// missing. A detail page is on it: what is cached is the page, and what makes
// it a page about one score or one set is read from this device, so leaving it
// off would not save a fetch — it would mean opening a score at a gig and being
// handed the scores list instead.
test('every page of the app is cached, including the ones that are about one thing', () => {
  const precached = new Set(precachedUrls());

  for (const page of [
    '/',
    '/profile.html',
    '/settings.html',
    '/scores/detail.html',
    '/scores/perform.html',
    '/sets/',
    '/sets/detail.html',
  ]) {
    assert.ok(precached.has(page), `${page} would not open without a network`);
  }
});

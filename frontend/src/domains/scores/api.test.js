import test from 'node:test';
import assert from 'node:assert/strict';

import {ApiConfig, ScoresApi} from './api.js';

/**
 * Calls getScores with fetch stubbed out and hands back the change window it
 * asked the API for.
 *
 * @param changesSince {Date|null}
 * @param changesUntil {Date|null}
 * @return {Promise<{since: Date, until: Date, raw: URLSearchParams}>}
 */
async function windowAskedFor(changesSince, changesUntil) {
  const original = globalThis.fetch;
  let requestedUrl;
  globalThis.fetch = async (url) => {
    requestedUrl = url;
    return {status: 200, statusText: 'OK', json: async () => [], text: async () => ''};
  };

  try {
    await new ScoresApi(new ApiConfig('http://localhost/')).getScores(changesSince, changesUntil, 'a-token');
  } finally {
    globalThis.fetch = original;
  }

  const params = new URL(requestedUrl).searchParams;
  return {
    since: parseApiDate(params.get('Changes-Since')),
    until: parseApiDate(params.get('Changes-Until')),
    raw: params,
  };
}

/**
 * Reads the YYYYMMDDThhmmss the API takes, which it reads as UTC.
 *
 * @param value {string}
 * @return {Date}
 */
function parseApiDate(value) {
  const match = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$/.exec(value);
  assert.ok(match, `"${value}" is not a date-time the API can read`);
  const [, year, month, day, hour, minute, second] = match;
  return new Date(Date.UTC(+year, +month - 1, +day, +hour, +minute, +second));
}

test('a change window is asked for in the format the API reads', async () => {
  const {raw} = await windowAskedFor(new Date('2026-08-03T18:39:14.800Z'), new Date('2026-08-03T19:00:00.000Z'));

  assert.match(raw.get('Changes-Since'), /^\d{8}T\d{6}$/);
  assert.match(raw.get('Changes-Until'), /^\d{8}T\d{6}$/);
});

// The API keeps everything that changed up to and including the end of the
// window, but only reads a moment to the second. Rounding the end down leaves
// out whatever changed during the second that is still running, which is how a
// score comes back missing from the list of scores immediately after being
// uploaded.
test('the end of a change window covers a score that changed a fraction of a second ago', async () => {
  const justUploadedAt = new Date('2026-08-03T18:39:14.686Z');
  const syncingAt = new Date('2026-08-03T18:39:14.900Z');

  const {until} = await windowAskedFor(new Date('2026-08-03T17:00:00.000Z'), syncingAt);

  assert.ok(until >= justUploadedAt,
    `a score changed at ${justUploadedAt.toISOString()} falls outside a window ending ${until.toISOString()}`);
  assert.ok(until >= syncingAt,
    `the window ends at ${until.toISOString()}, before the ${syncingAt.toISOString()} it was asked to cover`);
});

test('an end that is already a whole second is not pushed any further out', async () => {
  const exactly = new Date('2026-08-03T18:39:14.000Z');

  const {until} = await windowAskedFor(new Date('2026-08-03T17:00:00.000Z'), exactly);

  assert.equal(until.getTime(), exactly.getTime());
});

// Rounding the start down is what keeps it inclusive, the same way rounding the
// end up does at the other end.
test('the start of a change window covers a score that changed a fraction of a second into it', async () => {
  const askedFrom = new Date('2026-08-03T18:39:14.800Z');

  const {since} = await windowAskedFor(askedFrom, new Date('2026-08-03T19:00:00.000Z'));

  assert.ok(since <= askedFrom,
    `the window starts at ${since.toISOString()}, after the ${askedFrom.toISOString()} it was asked to cover`);
});

test('a window nothing was said about covers everything up to now', async () => {
  const before = new Date();

  const {since, until} = await windowAskedFor(null, null);

  assert.equal(since.getTime(), 0, 'a window with no start should begin at the epoch');
  assert.ok(until >= before,
    `the window ends at ${until.toISOString()}, before the ${before.toISOString()} it was asked for`);
});

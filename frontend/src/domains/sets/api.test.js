import test from 'node:test';
import assert from 'node:assert/strict';

import {SetsApi, SetsApiError} from './api.js';

/**
 * Calls the API with fetch stubbed out and hands back what it asked for.
 *
 * @param answer {{status: number, statusText?: string, body?: string}}
 * @param call {function(SetsApi): Promise<*>}
 * @return {Promise<{request: {url: string, options: Object}, result: *, error: *}>}
 */
async function called(answer, call) {
  const original = globalThis.fetch;
  let request;
  globalThis.fetch = async (url, options) => {
    request = {url, options: options ?? {}};
    const body = answer.body ?? '';
    return {
      status: answer.status,
      statusText: answer.statusText ?? '',
      ok: answer.status >= 200 && answer.status < 300,
      json: async () => JSON.parse(body),
      text: async () => body,
    };
  };

  let result = null;
  let error = null;
  try {
    result = await call(new SetsApi({baseUrl: 'http://localhost/'}));
  } catch (thrown) {
    error = thrown;
  } finally {
    globalThis.fetch = original;
  }

  return {request, result, error};
}

// ----------------------------------------------------------------------------
// WHAT IS ASKED FOR
// ----------------------------------------------------------------------------

test('a change window is asked for in the format the API reads', async () => {
  const {request} = await called({status: 200, body: '[]'}, (api) =>
    api.listSets(new Date('2026-08-03T18:39:14.800Z'), new Date('2026-08-03T19:00:00.000Z'), 'a-token'));

  const params = new URL(request.url).searchParams;
  assert.equal(params.get('Changes-Since'), '2026-08-03T18:39:14.800Z');
  assert.equal(params.get('Changes-Until'), '2026-08-03T19:00:00.000Z');
});

// The window ends at the moment it was asked to and not at the second it falls
// in, or a set written a fraction of a second ago is left out of the answer.
test('a window nothing was said about covers everything up to now', async () => {
  const before = new Date();

  const {request} = await called({status: 200, body: '[]'}, (api) =>
    api.listSets(null, null, 'a-token'));

  const params = new URL(request.url).searchParams;
  assert.equal(new Date(params.get('Changes-Since')).getTime(), 0);
  assert.ok(new Date(params.get('Changes-Until')) >= before);
});

test('a set is written as json, under the id it was given', async () => {
  const setId = 'c0ffee00-0000-4000-8000-000000000000';
  const {request} = await called({status: 200, body: '{"id":"' + setId + '"}'}, (api) =>
    api.putSet(setId, 'a-token', {title: 'Zomerbar', description: '', shared_with: []}));

  assert.equal(request.url, `http://localhost/sets/${setId}`);
  assert.equal(request.options.method, 'PUT');
  assert.equal(request.options.headers['Content-Type'], 'application/json');
  assert.equal(request.options.headers['Authorization'], 'Bearer a-token');
  assert.deepEqual(JSON.parse(request.options.body).title, 'Zomerbar');
});

// ----------------------------------------------------------------------------
// WHAT COMES BACK
// ----------------------------------------------------------------------------

test('a set that is not there is nothing rather than a failure', async () => {
  const {result, error} = await called({status: 404, body: '{"errorCode":"set_not_found"}'}, (api) =>
    api.getSet('a-set-that-was-never-written', 'a-token'));

  assert.equal(error, null);
  assert.equal(result, null);
});

// Deleting is asking for the set to be gone, and a set that is already gone is
// the state that was asked for.
test('deleting a set that is already gone is not a failure', async () => {
  const {error} = await called({status: 404, body: '{"errorCode":"set_not_found"}'}, (api) =>
    api.deleteSet('a-set-that-was-already-deleted', 'a-token'));

  assert.equal(error, null);
});

test('a failure carries the code the API says to branch on', async () => {
  const problem = {
    type: 'about:blank',
    title: 'Bad Request',
    status: 400,
    detail: 'no score found with the given id',
    instance: 'urn:uuid:5f6a2f1e-9b3c-4a7d-8e21-0c1d2e3f4a5b',
    errorCode: 'unknown_score',
  };

  const {error} = await called({status: 400, body: JSON.stringify(problem)}, (api) =>
    api.putSet('a-set', 'a-token', {title: '', description: '', shared_with: []}));

  assert.ok(error instanceof SetsApiError);
  assert.equal(error.status, 400);
  assert.equal(error.errorCode, 'unknown_score');
  assert.equal(error.problem.detail, 'no score found with the given id');
});

test('a failure with a body that is not problem details is still a failure', async () => {
  const {error} = await called({status: 502, statusText: 'Bad Gateway', body: '<html>nope</html>'}, (api) =>
    api.listSets(null, null, 'a-token'));

  assert.ok(error instanceof SetsApiError);
  assert.equal(error.status, 502);
  assert.equal(error.errorCode, null);
});

test('a call with nothing at the other end fails without a status', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = async () => {
    throw new TypeError('Failed to fetch');
  };

  let error = null;
  try {
    await new SetsApi({baseUrl: 'http://localhost/'}).listSets(null, null, 'a-token');
  } catch (thrown) {
    error = thrown;
  } finally {
    globalThis.fetch = original;
  }

  assert.ok(error instanceof SetsApiError);
  assert.equal(error.status, null, 'nothing answered, so nothing has a status');
});

// ----------------------------------------------------------------------------
// WHETHER A WRITE IS WORTH KEEPING
// ----------------------------------------------------------------------------

// This is what decides between keeping an edit queued and giving up on it, so
// it is worth being explicit about which failure is which.
test('a request the server refused to read is not worth making again', async () => {
  for (const status of [400, 404, 409, 413, 415, 422]) {
    assert.equal(new SetsApiError('refused', status).isWorthRetrying, false,
      `${status} says the request itself is wrong, and waiting does not change it`);
  }
});

test('a failure that says nothing about the request is worth trying again', async () => {
  for (const status of [null, 500, 502, 503, 504]) {
    assert.equal(new SetsApiError('failed', status).isWorthRetrying, true,
      `${status} says nothing about what was written`);
  }
});

test('a token that ran out is about the caller, not about what was written', async () => {
  assert.equal(new SetsApiError('unauthorized', 401).isWorthRetrying, true);
  assert.equal(new SetsApiError('forbidden', 403, {errorCode: 'missing_role'}).isWorthRetrying, true);
});

test('a set that belongs to someone else does not start belonging to us', async () => {
  assert.equal(new SetsApiError('forbidden', 403, {errorCode: 'not_set_owner'}).isWorthRetrying, false);
});

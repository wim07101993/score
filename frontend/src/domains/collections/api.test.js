import test from 'node:test';
import assert from 'node:assert/strict';

import {CollectionsApi, CollectionsApiError} from './api.js';

/**
 * Calls the API with fetch stubbed out and hands back what it asked for.
 *
 * @param answer {{status: number, statusText?: string, body?: string}}
 * @param call {function(CollectionsApi): Promise<*>}
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
    result = await call(new CollectionsApi({baseUrl: 'http://localhost/'}));
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
    api.listCollections(
      new Date('2026-08-03T18:39:14.800Z'),
      new Date('2026-08-03T19:00:00.000Z'),
      'a-token'));

  const params = new URL(request.url).searchParams;
  assert.equal(params.get('Changes-Since'), '2026-08-03T18:39:14.800Z');
  assert.equal(params.get('Changes-Until'), '2026-08-03T19:00:00.000Z');
});

test('a collection is written as json, under the id it was given', async () => {
  const collectionId = 'c0ffee00-0000-4000-8000-000000000000';
  const {request} = await called(
    {status: 200, body: `{"id":"${collectionId}"}`},
    (api) => api.putCollection(collectionId, 'a-token', {
      title: 'The Real Book',
      description: '',
      shared_with: [],
    }));

  assert.equal(request.url, `http://localhost/collections/${collectionId}`);
  assert.equal(request.options.method, 'PUT');
  assert.equal(request.options.headers['Content-Type'], 'application/json');
  assert.equal(request.options.headers['Authorization'], 'Bearer a-token');
  assert.equal(JSON.parse(request.options.body).title, 'The Real Book');
});

// An entry says what the group does with a piece and nothing about where it
// comes: a collection has no order to put one in.
test('an entry is written without a place in any order', async () => {
  const {request} = await called({status: 200, body: '{"id":"e-1"}'}, (api) =>
    api.putEntry('c-1', 'e-1', 'a-token', {
      score_id: 'a-score',
      description: 'page 62',
      transposition: -2,
    }));

  assert.equal(request.url, 'http://localhost/collections/c-1/entries/e-1');
  const written = JSON.parse(request.options.body);
  assert.equal(written.position, undefined, 'a collection has no running order');
  assert.equal(written.transposition, -2);
});

test('a view is written under the entry it is about', async () => {
  const {request} = await called({status: 200, body: '{}'}, (api) =>
    api.putEntryView('c-1', 'e-1', 'a-token',
      {transposition: 5, hidden_parts: ['P2'], zoom: 1.5}));

  assert.equal(request.url, 'http://localhost/collections/c-1/entries/e-1/view');
  assert.deepEqual(JSON.parse(request.options.body).hidden_parts, ['P2']);
});

// ----------------------------------------------------------------------------
// WHAT COMES BACK
// ----------------------------------------------------------------------------

test('a collection that is not there is nothing rather than a failure', async () => {
  const {result, error} = await called({status: 404, body: '{}'}, (api) =>
    api.getCollection('c-1', 'a-token'));

  assert.equal(error, null);
  assert.equal(result, null);
});

test('deleting what is already gone is not a failure', async () => {
  const {error} = await called({status: 404, body: '{}'}, (api) =>
    api.deleteCollection('c-1', 'a-token'));

  assert.equal(error, null, 'what was asked for is the state it is now in');
});

test('a refusal carries the code an application branches on', async () => {
  const {error} = await called({
    status: 403,
    body: '{"errorCode":"not_collection_owner","detail":"only the owner can change it"}',
  }, (api) => api.putCollection('c-1', 'a-token', {
    title: '', description: '', shared_with: [],
  }));

  assert.ok(error instanceof CollectionsApiError);
  assert.equal(error.status, 403);
  assert.equal(error.errorCode, 'not_collection_owner');
});

test('a body that is not problem details still fails as one', async () => {
  const {error} = await called({status: 502, body: '<html>gateway</html>'}, (api) =>
    api.getCollection('c-1', 'a-token'));

  assert.ok(error instanceof CollectionsApiError);
  assert.equal(error.status, 502);
  assert.equal(error.errorCode, null, 'something in between answered, not this API');
});

test('a network that is not there says nothing about the request', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = async () => {
    throw new TypeError('failed to fetch');
  };

  let error = null;
  try {
    await new CollectionsApi({baseUrl: 'http://localhost/'}).getCollection('c-1', 'a-token');
  } catch (thrown) {
    error = thrown;
  } finally {
    globalThis.fetch = original;
  }

  assert.ok(error instanceof CollectionsApiError);
  assert.equal(error.status, null);
  assert.ok(error.isWorthRetrying, 'nothing answered, so nothing was said about the request');
});

// ----------------------------------------------------------------------------
// WHETHER TO ASK AGAIN
// ----------------------------------------------------------------------------

test('a refusal about the request is not worth asking again', async () => {
  assert.equal(new CollectionsApiError('', 400, {errorCode: 'invalid_collection'})
    .isWorthRetrying, false);
  assert.equal(new CollectionsApiError('', 403, {errorCode: 'not_collection_owner'})
    .isWorthRetrying, false, 'waiting does not change whose collection it is');
});

test('a refusal about the caller or the server is worth asking again', async () => {
  assert.equal(new CollectionsApiError('', 401, null).isWorthRetrying, true);
  assert.equal(new CollectionsApiError('', 403, null).isWorthRetrying, true);
  assert.equal(new CollectionsApiError('', 503, null).isWorthRetrying, true);
});

// The one refusal that is worth acting on rather than reporting: what the
// caller wanted was the piece to be in the book, and it is.
test('the collection already holding the piece names the entry it is in', async () => {
  const error = new CollectionsApiError('', 409, {
    errorCode: 'score_already_in_collection',
    entryId: 'e-7',
  });

  assert.equal(error.isAlreadyInTheCollection, true);
  assert.equal(error.alreadyInEntryId, 'e-7');
  assert.equal(error.isWorthRetrying, false, 'it will be in the collection next time too');
});

test('anything else is not the collection already holding the piece', async () => {
  const error = new CollectionsApiError('', 404, {errorCode: 'collection_not_found'});

  assert.equal(error.isAlreadyInTheCollection, false);
  assert.equal(error.alreadyInEntryId, null);
});

import test from 'node:test';
import assert from 'node:assert/strict';

// The storage reads the sessionStorage global at call time, so a fake put here
// before importing is enough to drive it.
const store = new Map();
globalThis.sessionStorage = {
  setItem: (key, value) => store.set(key, String(value)),
  getItem: (key) => (store.has(key) ? store.get(key) : null),
  removeItem: (key) => store.delete(key),
};
globalThis.isSecureContext = true;

const {OidcStorage} = await import('./oidc-api.js');

test.beforeEach(() => store.clear());

test('a refresh token survives a round trip', () => {
  OidcStorage.refreshToken = 'a-refresh-token';

  assert.equal(OidcStorage.refreshToken, 'a-refresh-token');
});

// Clearing has to leave nothing behind. sessionStorage stringifies whatever it
// is handed, so storing null would leave the text "null", which every reader
// then mistakes for a token it can refresh with.
test('clearing the refresh token leaves no token behind', () => {
  OidcStorage.refreshToken = 'a-refresh-token';

  OidcStorage.refreshToken = null;

  assert.equal(OidcStorage.refreshToken, null);
});

test('a token response the provider sent without a refresh token clears it', () => {
  OidcStorage.refreshToken = 'a-refresh-token';

  OidcStorage.refreshToken = undefined;

  assert.equal(OidcStorage.refreshToken, null);
});

test('clearing the flow state leaves no flow state behind', () => {
  OidcStorage.oidcFlowState = {state: 'abc', codeVerifier: 'def'};
  assert.deepEqual(OidcStorage.oidcFlowState, {state: 'abc', codeVerifier: 'def'});

  OidcStorage.oidcFlowState = null;

  assert.equal(OidcStorage.oidcFlowState, null);
});

test('clearing the token response leaves no token response behind', () => {
  OidcStorage.tokenResponse = {access_token: 'a-token', expires_in: 0};
  assert.equal(OidcStorage.tokenResponse.access_token, 'a-token');

  OidcStorage.tokenResponse = null;

  assert.equal(OidcStorage.tokenResponse, null);
});

// expires_in counts seconds (RFC 6749 section 5.1). Treating it as
// milliseconds throws a perfectly good token away almost immediately, which
// sends every following request back through the refresh flow.
test('a token response is kept for as long as the provider said', (t) => {
  t.mock.timers.enable({apis: ['Date'], now: 0});

  OidcStorage.tokenResponse = {access_token: 'a-token', expires_in: 3600};

  t.mock.timers.tick(3500 * 1000);
  assert.notEqual(OidcStorage.tokenResponse, null, 'the token expired before the provider said it would');

  t.mock.timers.tick(100 * 1000);
  assert.equal(OidcStorage.tokenResponse, null, 'the token outlived what the provider said');
});

// This is the whole of the bug this replaced a timer to fix. A timer dies with
// the page: a tab closed with time left on a token and opened an hour later
// found the token still there, sent it, and was told 401 — which took the app
// down with it. When a token runs out is a thing the token has to carry.
test('a token response does not outlive the page it was stored on', (t) => {
  t.mock.timers.enable({apis: ['Date'], now: 0});
  OidcStorage.tokenResponse = {access_token: 'a-token', expires_in: 3600};

  // No timer runs here — this is a new page, reading what the last one left.
  t.mock.timers.tick(2 * 3600 * 1000);

  assert.equal(OidcStorage.tokenResponse, null);
});

// A token with a couple of seconds left is a token that arrives without any.
test('a token response is given up a little before it actually runs out', (t) => {
  t.mock.timers.enable({apis: ['Date'], now: 0});

  OidcStorage.tokenResponse = {access_token: 'a-token', expires_in: 60};

  t.mock.timers.tick(59 * 1000);

  assert.equal(OidcStorage.tokenResponse, null);
});

// A provider that did not say when is a token this app cannot date, and it is
// not going to throw one away on a guess: it finds out by being refused.
test('a token response the provider put no time on is kept', (t) => {
  t.mock.timers.enable({apis: ['Date'], now: 0});

  OidcStorage.tokenResponse = {access_token: 'a-token', expires_in: 0};

  t.mock.timers.tick(100 * 24 * 3600 * 1000);

  assert.equal(OidcStorage.tokenResponse.access_token, 'a-token');
});

test('a token response that replaced an expiring one is not dropped with it', (t) => {
  t.mock.timers.enable({apis: ['Date'], now: 0});

  OidcStorage.tokenResponse = {access_token: 'first', expires_in: 60};
  OidcStorage.tokenResponse = {access_token: 'second', expires_in: 3600};

  t.mock.timers.tick(60 * 1000);

  assert.equal(OidcStorage.tokenResponse.access_token, 'second');
});

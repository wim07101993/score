import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';

// The module picks its hashing strategy based on this global.
globalThis.isSecureContext = true;

const {OidcFlowState, UserInfoResponse} = await import('./oidc-api.js');

/**
 * @param verifier {string}
 * @return {string} the code challenge an OIDC provider computes for a verifier:
 *   BASE64URL(SHA256(ASCII(verifier))), see RFC 7636 section 4.2.
 */
function expectedCodeChallenge(verifier) {
  return createHash('sha256').update(verifier, 'ascii').digest('base64url');
}

test('createCodeChallenge matches the RFC 7636 test vector', async () => {
  // Appendix B of RFC 7636.
  const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';

  assert.equal(
    await OidcFlowState.createCodeChallenge(verifier),
    'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
  );
});

test('createCodeChallenge is the base64url encoded sha256 of the verifier', async () => {
  // Around half of all digests base64 encode to something containing a "/" or
  // a "+", so a handful of verifiers is enough to catch an encoding that only
  // works some of the time.
  const verifiers = Array.from({length: 32}, (_, i) => `verifier-${i}`.padEnd(43, '0'));

  for (const verifier of verifiers) {
    assert.equal(
      await OidcFlowState.createCodeChallenge(verifier),
      expectedCodeChallenge(verifier),
      `wrong challenge for verifier ${verifier}`,
    );
  }
});

test('createCodeChallenge only produces base64url characters', async () => {
  const verifiers = Array.from({length: 32}, (_, i) => `verifier-${i}`.padEnd(43, '0'));

  for (const verifier of verifiers) {
    const challenge = await OidcFlowState.createCodeChallenge(verifier);
    assert.match(challenge, /^[A-Za-z0-9_-]+$/, `challenge ${challenge} is not base64url`);
  }
});

test('Create builds a flow state that satisfies the PKCE requirements', async () => {
  const state = await OidcFlowState.Create();

  assert.equal(state.codeChallengeMethod, 'S256');
  assert.match(state.state, /^[A-Za-z0-9]{16}$/);

  // RFC 7636 section 4.1 requires a verifier of 43 to 128 characters.
  assert.ok(
    state.codeVerifier.length >= 43 && state.codeVerifier.length <= 128,
    `code verifier of length ${state.codeVerifier.length} is outside the 43..128 range`,
  );
  assert.match(state.codeVerifier, /^[A-Za-z0-9\-._~]+$/);

  assert.equal(state.codeChallenge, await OidcFlowState.createCodeChallenge(state.codeVerifier));
});

test('Create produces a different state and verifier every time', async () => {
  const first = await OidcFlowState.Create();
  const second = await OidcFlowState.Create();

  assert.notEqual(first.state, second.state);
  assert.notEqual(first.codeVerifier, second.codeVerifier);
});

// ---------------------------------------------------------------------------
// WHAT THE PROVIDER SAID ABOUT THE USER
// ---------------------------------------------------------------------------

const ROLES_KEY = 'urn:zitadel:iam:org:project:roles';

/** @param overrides {Object} */
function aUserInfoAnswer(overrides = {}) {
  return {
    sub: '2c8f7a1b-3d4e-4a5f-9b6c-7d8e9f0a1b2c',
    name: 'Wim Van Laer',
    email: 'wim@example.com',
    [ROLES_KEY]: {score_viewer: {'org-id': 'example.com'}},
    ...overrides,
  };
}

test('the roles are read out of the claim the config names', () => {
  const user = UserInfoResponse.fromResponse(aUserInfoAnswer(), ROLES_KEY);

  assert.equal(user.isScoreViewer, true);
  assert.equal(user.isScoreEditor, false);
  assert.equal(user.name, 'Wim Van Laer');
  assert.equal(user.email, 'wim@example.com');
});

// Which claim the roles arrive under is the provider's to decide and the
// config's to state, and when the two disagree there is nothing to read.
test('roles under a claim nobody looked under are no roles at all', () => {
  const user = UserInfoResponse.fromResponse(aUserInfoAnswer(), 'some:other:claim');

  assert.equal(user.isScoreViewer, false);
  assert.equal(user.roles, null);
});

// What the app was told is what explains what it decided, so it is kept rather
// than boiled down to the two questions this app happens to ask today.
test('the answer it was read out of is kept, and so is where it looked', () => {
  const answer = aUserInfoAnswer();

  const user = UserInfoResponse.fromResponse(answer, ROLES_KEY);

  assert.deepEqual(user.claims, answer);
  assert.equal(user.rolesKey, ROLES_KEY);
});

// This is what went wrong: the user kept on the device came back from
// JSON.parse as a plain object, which carries the fields but none of the
// methods. `isScoreViewer` on one of those is not false but undefined, and
// every page reads it as "no". A user with every role would be shown nothing
// at all as soon as the provider could not be reached.
test('a user read back from the storage still has their roles', () => {
  const stored = JSON.parse(JSON.stringify(
    UserInfoResponse.fromResponse(aUserInfoAnswer({
      [ROLES_KEY]: {score_viewer: {}, score_editor: {}},
    }), ROLES_KEY)));

  const user = UserInfoResponse.fromJson(stored);

  assert.equal(user.isScoreViewer, true, 'a user kept on the device lost the roles they had');
  assert.equal(user.isScoreEditor, true);
  assert.equal(user.name, 'Wim Van Laer');
  assert.equal(user.subject, '2c8f7a1b-3d4e-4a5f-9b6c-7d8e9f0a1b2c');
  assert.equal(user.rolesKey, ROLES_KEY);
});

test('nothing kept on the device is nobody, not an empty user', () => {
  assert.equal(UserInfoResponse.fromJson(null), null);
  assert.equal(UserInfoResponse.fromJson('not an object'), null);
});

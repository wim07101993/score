import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';

// The module picks its hashing strategy based on this global.
globalThis.isSecureContext = true;

const {OidcFlowState} = await import('./oidc-api.js');

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

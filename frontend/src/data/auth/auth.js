import {authConfig, defaultScopes} from "./config.js";

const pkceCodeVerifierSessionStorageKey = 'pkce_code_verifier';
const idTokenSessionStorageKey = 'id_token';

const refreshTokenLocalStorageKey = 'refresh_token';

export const authorizationCodeQueryParamName = 'code';

/**
 * The last received access token.
 * @type {TokenResponse|null} string
 */
let tokenResponse = null;

/**
 * @returns {Promise<string>}
 */
export async function authorize() {
  if (tokenResponse !== null) {
    return tokenResponse.access_token;
  }

  const urlParams = new URLSearchParams(window.location.search);
  const authorizationCode = urlParams.get(authorizationCodeQueryParamName);

  const codeVerifier = sessionStorage.getItem(pkceCodeVerifierSessionStorageKey);
  if (codeVerifier !== null && authorizationCode !== null && authorizationCode.length !== 0) {
    console.log('exchange authorization code for token');
    tokenResponse = await callTokenEndpoint(
      authConfig.tokenEndpoint,
      TokenRequestParams.authorizationCode(
        authConfig.clientId,
        'authorization_code',
        authConfig.redirectUri,
        authorizationCode,
        codeVerifier)
    );
    if (tokenResponse !== null) {
      return tokenResponse.access_token;
    }
  }

  const refreshToken = localStorage.getItem(refreshTokenLocalStorageKey);
  if (refreshToken !== null) {
    console.log('refresh access token');
    tokenResponse = await callTokenEndpoint(
      authConfig.tokenEndpoint,
      TokenRequestParams.refreshToken(
        authConfig.clientId,
        'refresh_token',
        authConfig.redirectUri,
        defaultScopes,
        refreshToken
      )
    );
    if (tokenResponse !== null) {
      return tokenResponse.access_token;
    }
  }

  await startAuthorizationCodeFlow(
    authConfig.clientId,
    authConfig.redirectUri,
    authConfig.authorizationEndpoint,
    defaultScopes
  );
  return null;
}

/**
 * Starts the authorization code flow. This means this function will redirect the
 * application to the IDP for login. When that is done it will redirect back with
 * an authorization code which can be used to request a token.
 *
 * @param clientId {string}
 * @param redirectUri {URL}
 * @param authorizationEndpoint {URL}
 * @param scope {string[]}
 */
async function startAuthorizationCodeFlow(clientId, redirectUri, authorizationEndpoint, scope) {
  console.log('start authorization code flow');
  const codeVerifier = generateRandomString(56);
  const codeChallenge = await createCodeChallenge(codeVerifier);

  sessionStorage.setItem(pkceCodeVerifierSessionStorageKey, codeVerifier);

  const authParams = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri.toString(),
    scope: scope.join(' '),
    response_type: 'code',
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
    state: 'my-random-state-string'
  })

  const authUrl = `${authorizationEndpoint.protocol}//${authorizationEndpoint.host}${authorizationEndpoint.pathname}?${authParams.toString()}`;
  console.log(`navigating for auth: ${authUrl}`);
  window.location.href = authUrl;

  // return false needs to be here to make the redirect work...
  return false;
}

/**
 * Makes a POST request to the token endpoint of the IDP and handles its
 * response.
 *
 * @param tokenEndpoint {URL} is the url to call.
 * @param authParams {TokenRequestParams} parameters to add to the request
 * @returns {Promise<TokenResponse|null>}
 */
async function callTokenEndpoint(tokenEndpoint, authParams) {
  try {
    const response = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: authParams.toUrlSearchParams().toString(),
    });

    const body = await response.json();

    if (!response.ok) {
      console.log('Error while requesting token', body);
      return null;
    }

    /**
     * @type {TokenResponse}
     */
    const tokenResponse = body
    localStorage.setItem(refreshTokenLocalStorageKey, tokenResponse.refresh_token);
    sessionStorage.setItem(idTokenSessionStorageKey, tokenResponse.id_token);

    return tokenResponse;
  } catch (error) {
    console.log('Error while requesting token', error);
    return null;
  } finally {
    sessionStorage.removeItem(pkceCodeVerifierSessionStorageKey);
  }
}

/**
 * @param {number} length is the length of requested string
 * @returns {string} A random string ([A-Za-z0-9]+)
 */
function generateRandomString(length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array
    .from(array, n => chars[n % chars.length])
    .join();
}

/**
 * @param {string} verifier is the verifier which should be used for the challenge
 * @returns {Promise<string>} The SHA256 hashed input.
 */
async function createCodeChallenge(verifier) {
  const messageBuffer = new TextEncoder().encode(verifier);
  const hashBuff = await crypto.subtle.digest('SHA-256', messageBuffer);
  const hashStr = String.fromCharCode(...new Uint8Array(hashBuff));

  return btoa(hashStr) // base64 encode
    .replace(/\+/g, '-')
    .replace(/\//g, '-')
    .replace(/=+$/, '');
}

/**
 * Request with which a token can be requested from the IDP.
 */
class TokenRequestParams {
  /**
   * @param client_id {string}
   * @param grant_type {"refresh_token"|"authorization_code"}
   * @param redirect_uri {URL}
   * @param scope {string[]|null}
   * @param refresh_token {string|null}
   * @param code {string|null}
   * @param code_verifier {string|null}
   */
  constructor(
    client_id,
    grant_type,
    redirect_uri,
    scope,
    refresh_token,
    code,
    code_verifier) {
    this.clientId = client_id;
    this.grantType = grant_type;
    this.redirectUri = redirect_uri;
    this.scope = scope;
    this.refreshToken = refresh_token;
    this.code = code;
    this.codeVerifier = code_verifier;
  }

  /**
   * @param clientId {string}
   * @param grantType {"refresh_token"|"authorization_code"}
   * @param redirectUrl {URL}
   * @param code {string}
   * @param codeVerifier {string}
   */
  static authorizationCode(clientId, grantType, redirectUrl, code, codeVerifier) {
    return new TokenRequestParams(clientId, grantType, redirectUrl, null, null, code, codeVerifier);
  }

  /**
   * @param clientId {string}
   * @param grantType {"refresh_token"|"authorization_code"}
   * @param redirectUrl {URL}
   * @param scope {string[]}
   * @param refreshToken {string}
   */
  static refreshToken(clientId, grantType, redirectUrl, scope, refreshToken) {
    return new TokenRequestParams(clientId, grantType, redirectUrl, scope, refreshToken, null, null);
  }

  toUrlSearchParams() {
    return new URLSearchParams({
      client_id: this.clientId,
      grant_type: this.grantType,
      redirect_uri: this.redirectUri.toString(),
      scope: this.scope?.join(' '),
      refresh_token: this.refreshToken,
      code: this.code,
      code_verifier: this.codeVerifier,
    });
  }
}

/**
 * Response from the token endpoint after requesting a token from the IDP.
 */
class TokenResponse {
  /**
   * @param access_token {string}
   * @param refresh_token {string|null}
   * @param expires_in {number}
   * @param id_token {string}
   * @param token_type {string}
   */
  constructor(
    access_token,
    refresh_token,
    expires_in,
    id_token,
    token_type,
  ) {
    this.access_token = access_token;
    this.refresh_token = refresh_token;
    this.expires_in = expires_in;
    this.id_token = id_token;
    this.token_type = token_type;
  }
}

const pkceCodeVerifierSessionStorageKey = 'oauth_pkce_code_verifier';
const stateSessionStorageKey = 'oauth_state';
const idTokenSessionStorageKey = 'id_token';

const refreshTokenLocalStorageKey = 'refresh_token';
const scopes = ['openid', 'email', 'profile', 'offline_access'];

export class AuthConfig {
  /**
   * @param clientId {string}
   * @param redirectUri {URL}
   * @param authorizationEndpoint {URL}
   * @param tokenEndpoint {URL}
   * @param userInfoEndpoint {URL}
   * @param rolesKey {string}
   */
  constructor(
    clientId,
    redirectUri,
    authorizationEndpoint,
    tokenEndpoint,
    userInfoEndpoint,
    rolesKey) {
    this.clientId = clientId;
    this.redirectUri = redirectUri;
    this.authorizationEndpoint = authorizationEndpoint;
    this.tokenEndpoint = tokenEndpoint;
    this.userInfoEndpoint = userInfoEndpoint;
    this.rolesKey = rolesKey;
  }
}

// ----------------------------------------------------------------------------
// SERVICE
// ----------------------------------------------------------------------------

export class AuthorizationService {
  /**
   * @param config {AuthConfig}
   */
  constructor(config) {
    this.config = config;
  }

  /**
   * The last received access token.
   * @type {TokenResponse|null} string
   */
  tokenResponse = null;

  /**
   * @returns {Promise<string>}
   */
  async authorize() {
    if (this.tokenResponse !== null) {
      return this.tokenResponse.access_token;
    }

    const urlParams = new URLSearchParams(window.location.search);
    const authorizationCode = urlParams.get('code');
    const receivedState = urlParams.get('state');

    const codeVerifier = sessionStorage.getItem(pkceCodeVerifierSessionStorageKey);
    const createdState = sessionStorage.getItem(stateSessionStorageKey);
    if (codeVerifier !== null
      && authorizationCode !== null && authorizationCode.length !== 0
      && createdState !== null && createdState === receivedState) {
      console.log('exchange authorization code for token');
      this.tokenResponse = await callTokenEndpoint(
        this.config.tokenEndpoint,
        TokenRequestParams.authorizationCode(
          this.config.clientId,
          'authorization_code',
          this.config.redirectUri,
          authorizationCode,
          codeVerifier)
      );
      if (this.tokenResponse !== null) {
        sessionStorage.removeItem(pkceCodeVerifierSessionStorageKey);
        sessionStorage.removeItem(stateSessionStorageKey);
        return this.tokenResponse.access_token;
      }
    }

    const refreshToken = localStorage.getItem(refreshTokenLocalStorageKey);
    if (refreshToken !== null) {
      console.log('refresh access token');
      this.tokenResponse = await callTokenEndpoint(
        this.config.tokenEndpoint,
        TokenRequestParams.refreshToken(
          this.config.clientId,
          'refresh_token',
          this.config.redirectUri,
          scopes,
          refreshToken
        )
      );
      if (this.tokenResponse !== null) {
        return this.tokenResponse.access_token;
      } else {
        localStorage.removeItem(refreshTokenLocalStorageKey);
      }
    }

    await startAuthorizationCodeFlow(
      this.config.clientId,
      this.config.redirectUri,
      this.config.authorizationEndpoint,
      scopes
    );
    return null;
  }

  /**
   * @return {Promise<UserInfoResponse|null>}
   */
  async getUserInfo() {
    return await callUserInfoEndpoint(
      this.config.userInfoEndpoint,
      this.tokenResponse.access_token,
      this.config.rolesKey);
  }
}

// ----------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------

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
  const state = generateRandomString(16);

  sessionStorage.setItem(pkceCodeVerifierSessionStorageKey, codeVerifier);
  sessionStorage.setItem(stateSessionStorageKey, state);

  const authParams = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri.toString(),
    scope: scope.join(' '),
    response_type: 'code',
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
    state: state
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
 * @param userInfoEndpoint {URL}
 * @param accessToken {string}
 * @param rolesKey {string}
 * @return {Promise<UserInfoResponse|null>}
 */
async function callUserInfoEndpoint(userInfoEndpoint, accessToken, rolesKey) {
  try {
    const response  =await fetch(userInfoEndpoint,{
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });

    const body = await response.json();

    return UserInfoResponse.fromResponse(body, rolesKey);
  } catch (error) {
    console.log('Error while getting user info', error)
    return null;
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
    .join('');
}

/**
 * @param {string} verifier is the verifier which should be used for the challenge
 * @returns {Promise<string>} The SHA256 hashed input.
 */
async function createCodeChallenge(verifier) {
  const verifierHash = await sha256(verifier)

  return btoa(verifierHash) // base64 encode
    .replace(/\+/g, '-')
    .replace(/\//g, '-')
    .replace(/=+$/, '');
}

/**
 * Hashes a given input string as a SHA256. This function exists because the
 * crypto functionality of a browser does not exist inside an "insecure context"
 * like our dev-evn.
 *
 * @param input {string}
 * @return {Promise<string>}
 */
async function sha256(input) {
  if (isSecureContext) {
    const buffer = new TextEncoder().encode(input);
    const hashBuff = await crypto.subtle.digest('SHA-256', buffer);
    return String.fromCharCode(...new Uint8Array(hashBuff));
  }

  console.warn('Running in insecure context. Using CryptoJS instead of browser built-in');
  if (!window.CryptoJS) {
    await new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'https://cdn.jsdelivr.net/npm/crypto-js@4.2.0/crypto-js.min.js';
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }
  return CryptoJS.SHA256(input).toString(CryptoJS.enc.Hex);
}

// ----------------------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------------------

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

export class UserInfoResponse {
  /**
   * @param name {string}
   * @param subject {string}
   * @param roles {Object}
   */
  constructor(name, subject, roles){
    this.name = name;
    this.subject = subject;
    this.roles = roles;
  }

  /**
   * @return {boolean}
   */
  get isScoreEditor()  {
    return this.roles != null && this.roles['score_editor'] != null;
  }

  get isScoreViewer() {
    return this.roles != null && this.roles['score_viewer'] != null;
  }

  /**
   * @param response {Object}
   * @param rolesKey {string}
   * @return {UserInfoResponse}
   */
  static fromResponse(response, rolesKey) {
    return new UserInfoResponse(
      response['name'] + '',
      response['sub'] + '',
      response[rolesKey]
    );
  }
}

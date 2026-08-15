import {canBeReached} from "../../data/helper-functions.js";

const scopes = ['openid', 'email', 'profile', 'offline_access'];

export class OidcConfig {
  /**
   * @param clientId {string}
   * @param redirectUri {URL}
   * @param authorizationEndpoint {URL} oidc endpoint to authorize the client
   * @param tokenEndpoint {URL} oidc endpoint to get a token
   * @param userInfoEndpoint {URL} oidc endpoint to get info about the user
   * @param healthzEndpoint {URL} endpoint to check whether the oidc service is reachable
   * @param rolesKey {string} the key with which the roles of a user can be retrieved from the user info object.
   */
  constructor(
    clientId,
    redirectUri,
    authorizationEndpoint,
    tokenEndpoint,
    userInfoEndpoint,
    healthzEndpoint,
    rolesKey) {
    this.clientId = clientId;
    this.redirectUri = redirectUri;
    this.authorizationEndpoint = authorizationEndpoint;
    this.tokenEndpoint = tokenEndpoint;
    this.userInfoEndpoint = userInfoEndpoint;
    this.healthzEndpoint = healthzEndpoint;
    this.rolesKey = rolesKey;
  }
}

/**
 * Something the provider said no to.
 *
 * The status is kept because two of the answers mean different things to this
 * app: a provider that will not take a token is telling this device that the
 * token is no good, which is the device's to put right, and a provider that is
 * unwell is telling it nothing at all.
 */
export class OidcApiError extends Error {
  /**
   * @param message {string}
   * @param status {number}
   */
  constructor(message, status) {
    super(message);
    this.name = 'OidcApiError';
    this.status = status;
  }

  /**
   * Whether the provider refused what it was shown rather than failing to look
   * at it. A token that has run out, been revoked, or was signed with a key
   * that has since been rolled all land here.
   *
   * @return {boolean}
   */
  get isTokenRefused() {
    return this.status === 401 || this.status === 403;
  }
}

export class OidcApi {
  /**
   * @param oidcConfig {OidcConfig}
   */
  constructor(oidcConfig) {
    this._oidcConfig = oidcConfig;
  }

  async getFreshAccessToken() {
    let oidcFlowState = OidcStorage.oidcFlowState;
    if (oidcFlowState != null) {
      const urlParams = new URLSearchParams(window.location.search);
      const authorizationCode = urlParams.get('code');
      const receivedState = urlParams.get('state');
      if (authorizationCode !== null && authorizationCode.length !== 0 && oidcFlowState.state === receivedState) {
        // received callback from oidc server that an authorization which we started
        // has finished
        console.log('exchange authorization code for token');
        try {
          const tokenResponse = await OidcApi.callTokenEndpoint(
            this._oidcConfig.tokenEndpoint,
            TokenRequestParams.authorizationCode(this._oidcConfig.clientId, this._oidcConfig.redirectUri, authorizationCode, oidcFlowState.codeVerifier)
          );

          OidcStorage.tokenResponse = tokenResponse;
          OidcStorage.refreshToken = tokenResponse.refresh_token;
          return tokenResponse.access_token;
        } catch (e) {
          console.error('failed to exchange code for token', e);
          OidcStorage.tokenResponse = null;
          OidcStorage.refreshToken = null;
        } finally {
          OidcStorage.oidcFlowState = null;
        }
      }
    }

    const refreshToken = OidcStorage.refreshToken;
    if (refreshToken !== null) {
      console.log('refresh access token');
      try {
        const tokenResponse = await OidcApi.callTokenEndpoint(
          this._oidcConfig.tokenEndpoint,
          TokenRequestParams.refreshToken(this._oidcConfig.clientId, this._oidcConfig.redirectUri, scopes, refreshToken)
        );

        OidcStorage.tokenResponse = tokenResponse;
        OidcStorage.refreshToken = tokenResponse.refresh_token;
        return tokenResponse.access_token;
      } catch (e) {
        console.error('failed to exchange refresh token for token', e);
        OidcStorage.tokenResponse = null;
        OidcStorage.refreshToken = null;
      }
    }

    console.log('no callback happened or refresh-token received, initiating code flow');
    oidcFlowState = await OidcFlowState.Create();
    OidcStorage.oidcFlowState = oidcFlowState;
    OidcApi.navigateToAuthorizationEndpoint(this._oidcConfig, scopes, oidcFlowState);

    return null;
  }

  async getActiveAccessToken() {
    const tokenResponse = OidcStorage.tokenResponse;
    if (tokenResponse != null && tokenResponse.access_token != null) {
      return tokenResponse.access_token;
    }
    return await this.getFreshAccessToken();
  }

  /**
   * Asks the provider who is signed in.
   *
   * A token this app is holding can be refused however carefully it was dated:
   * a session ended at the provider, a key rolled, a clock that disagrees. So a
   * refusal is not an answer about the user, it is an answer about the token —
   * that one is thrown away and the question asked again with a fresh one,
   * which is what reloading the page used to do by accident.
   *
   * It is asked once more and no further. A provider that refuses a token it
   * has just issued is a provider that will go on refusing, and a loop between
   * the two of them is worse than being told.
   *
   * @return {Promise<UserInfoResponse>}
   */
  async getUserInfo() {
    const accessToken = await this.getActiveAccessToken();
    if (accessToken == null)
      throw new OidcApiError('failed to get access-token to getUserInfo', 401);

    try {
      return await OidcApi.callUserInfoEndpoint(
        this._oidcConfig.userInfoEndpoint,
        accessToken,
        this._oidcConfig.rolesKey
      );
    } catch (error) {
      if (!(error instanceof OidcApiError) || !error.isTokenRefused) {
        throw error;
      }

      console.log('the provider would not take the access token; asking for a new one');
      OidcStorage.tokenResponse = null;
      const freshAccessToken = await this.getFreshAccessToken();
      if (freshAccessToken == null) {
        // Either the provider has been navigated to and this page is on its way
        // out, or there was nothing to ask with. Neither is an answer.
        throw error;
      }

      return await OidcApi.callUserInfoEndpoint(
        this._oidcConfig.userInfoEndpoint,
        freshAccessToken,
        this._oidcConfig.rolesKey
      );
    }
  }

  /**
   * Whether the provider is there to be asked.
   *
   * A provider that cannot be reached is answered `false` rather than thrown
   * about: this is asked to find out whether to work from what is kept on the
   * device, and a network that is down is the very case it is asked in.
   *
   * @return {Promise<boolean>}
   */
  async canBeReached() {
    return await canBeReached(this._oidcConfig.healthzEndpoint);
  }

  /**
   * Makes a POST request to the token endpoint of the IDP and handles its
   * response.
   *
   * @param tokenEndpoint {URL} is the url to call.
   * @param authParams {TokenRequestParams} parameters to add to the request
   * @returns {Promise<TokenResponse>}
   */
  static async callTokenEndpoint(tokenEndpoint, authParams) {
    const response = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: authParams.toUrlSearchParams().toString(),
    });

    if (response.status >= 400) {
      throw new OidcApiError(
        `failed to get access-token: ${response.status} ${response.statusText}: ${await response.text()}`,
        response.status,
      );
    }

    return await response.json();
  }

  /**
   * @param userInfoEndpoint {URL}
   * @param accessToken {string}
   * @param rolesKey {string}
   * @return {Promise<UserInfoResponse>}
   */
  static async callUserInfoEndpoint(userInfoEndpoint, accessToken, rolesKey) {

    const response = await fetch(userInfoEndpoint, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });

    if (response.status >= 400) {
      throw new OidcApiError(
        `failed to get user info: ${response.status} ${response.statusText}: ${await response.text()}`,
        response.status,
      );
    }

    const body = await response.json();
    return UserInfoResponse.fromResponse(body, rolesKey);
  }

  /**
   * @param oidcConfig {OidcConfig}
   * @param scopes {string[]}
   * @param oidcFlowState {OidcFlowState}
   */
  static navigateToAuthorizationEndpoint(oidcConfig, scopes, oidcFlowState) {
    const authParams = new URLSearchParams({
      client_id: oidcConfig.clientId,
      redirect_uri: oidcConfig.redirectUri.toString(),
      scope: scopes.join(' '),
      response_type: 'code',
      code_challenge: oidcFlowState.codeChallenge,
      code_challenge_method: oidcFlowState.codeChallengeMethod,
      state: oidcFlowState.state
    })

    const authUrl = `${oidcConfig.authorizationEndpoint.protocol}//${oidcConfig.authorizationEndpoint.host}${oidcConfig.authorizationEndpoint.pathname}?${authParams.toString()}`;
    console.log(`navigating for auth: ${authUrl}`);
    window.location.href = authUrl;

    // return false needs to be here to make the redirect work...
    return false;
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
 * Hashes a given input string as a SHA256. This function exists because the
 * crypto functionality of a browser does not exist inside an "insecure context"
 * like our dev-evn.
 *
 * @param input {string}
 * @return {Promise<string>} the digest as a binary string, one character per
 *   byte, which is what btoa expects.
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
  return window.CryptoJS.SHA256(input).toString(window.CryptoJS.enc.Latin1);
}


// ----------------------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------------------

export class OidcFlowState {
  /**
   *
   * @param state {string}
   * @param codeVerifier {string}
   * @param codeChallenge {string}
   * @param codeChallengeMethod {string}
   */
  constructor(state, codeVerifier, codeChallenge, codeChallengeMethod) {
    this.state = state;
    this.codeVerifier = codeVerifier;
    this.codeChallenge = codeChallenge;
    this.codeChallengeMethod = codeChallengeMethod;
  }

  /**
   * @return {Promise<OidcFlowState>}
   */
  static async Create() {
    const state = generateRandomString(16);
    const codeVerifier = generateRandomString(56);
    const codeChallenge = await OidcFlowState.createCodeChallenge(codeVerifier);

    return new OidcFlowState(state, codeVerifier, codeChallenge, 'S256');
  }

  /**
   * @param {string} verifier is the verifier which should be used for the challenge
   * @returns {Promise<string>} The SHA256 hashed input.
   */
  static async createCodeChallenge(verifier) {
    const verifierHash = await sha256(verifier)

    return btoa(verifierHash) // base64 encode
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
  }
}

/**
 * Response from the token endpoint after requesting a token from the IDP.
 */
export class TokenResponse {
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
export class TokenRequestParams {
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
   * @param redirectUrl {URL}
   * @param code {string}
   * @param codeVerifier {string}
   */
  static authorizationCode(clientId, redirectUrl, code, codeVerifier) {
    return new TokenRequestParams(clientId, 'authorization_code', redirectUrl, null, null, code, codeVerifier);
  }

  /**
   * @param clientId {string}
   * @param redirectUrl {URL}
   * @param scope {string[]}
   * @param refreshToken {string}
   */
  static refreshToken(clientId, redirectUrl, scope, refreshToken) {
    return new TokenRequestParams(clientId, 'refresh_token', redirectUrl, scope, refreshToken, null, null);
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
   * Which claims a user-info response carries is up to the provider, so every
   * one of these can be absent.
   *
   * The claims it was read out of are kept alongside it. What a provider
   * answers with is the one thing that explains why this app thinks what it
   * thinks about a user — which is worth being able to show when it thinks
   * something the user disagrees with.
   *
   * @param name {string|null}
   * @param subject {string|null}
   * @param email {string|null}
   * @param roles {Object|null}
   * @param claims {Object|null} the answer this was read out of
   * @param rolesKey {string|null} the claim the roles were looked for under
   */
  constructor(name, subject, email, roles, claims = null, rolesKey = null) {
    this.name = name;
    this.subject = subject;
    this.email = email;
    this.roles = roles;
    this.claims = claims;
    this.rolesKey = rolesKey;
  }

  /**
   * @return {boolean}
   */
  get isScoreEditor() {
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
    // A claim the provider did not send is absent, not the text "undefined",
    // which is what concatenating an empty string onto it would produce.
    return new UserInfoResponse(
      response['name'] ?? null,
      response['sub'] ?? null,
      response['email'] ?? null,
      response[rolesKey] ?? null,
      response,
      rolesKey
    );
  }

  /**
   * The same user, read back from what {@link JSON.stringify} made of one.
   *
   * What comes out of `JSON.parse` is a plain object: it carries the fields but
   * none of the methods, so `isScoreViewer` on it is not `false` but `undefined`
   * — and every question this app asks about a user is asked that way. Reading
   * it back into a user is what keeps a user who is kept on the device from
   * being a user with no roles at all.
   *
   * @param json {Object|null}
   * @return {UserInfoResponse|null}
   */
  static fromJson(json) {
    if (json == null || typeof json !== 'object') {
      return null;
    }
    return new UserInfoResponse(
      json.name ?? null,
      json.subject ?? null,
      json.email ?? null,
      json.roles ?? null,
      json.claims ?? null,
      json.rolesKey ?? null
    );
  }
}

const oidcFlowStateSessionStorageKey = 'auth_oidc_flow_state';
const tokenResponseSessionStorageKey = 'auth_token_response';
const refreshTokenSessionStorageKey = 'auth_refresh_token';

/**
 * How long before it actually runs out a token is treated as run out. A request
 * carrying a token with two seconds left is a request that arrives without one.
 *
 * @type {number}
 */
const tokenExpiryMargin = 30 * 1000;

/**
 * Writes a value to the session storage, or clears the key when there is no
 * value. Storing null is not the same as clearing: setItem stringifies, so it
 * would leave the string "null" behind for the next reader to trip over.
 *
 * @param key {string}
 * @param value {string|null|undefined}
 */
function setOrRemove(key, value) {
  if (value == null) {
    sessionStorage.removeItem(key);
    return;
  }
  sessionStorage.setItem(key, value);
}

export class OidcStorage {

  /**
   * @param value {TokenResponse|null}
   */
  static set tokenResponse(value) {
    if (value == null) {
      setOrRemove(tokenResponseSessionStorageKey, null);
      return;
    }
    // When it runs out, rather than how long it had left when it arrived.
    //
    // This used to be a timer that cleared the token when it expired, and a
    // timer cannot say this: it dies with the page. A tab closed with five
    // minutes left on a token and opened again an hour later found the token
    // still sitting in the storage with nothing left to clear it, handed it to
    // the provider, and was told 401 — which is a thing this app can now say
    // for itself, before asking anybody.
    setOrRemove(tokenResponseSessionStorageKey, JSON.stringify({
      ...value,
      // A provider that did not say when is a token this app cannot date, and
      // one it will not throw away on a guess. It finds out the way it always
      // did: by being refused.
      expires_at: value.expires_in > 0 ? Date.now() + value.expires_in * 1000 : null,
    }));
  }

  /**
   * @return {TokenResponse|null}
   */
  static get tokenResponse() {
    const json = sessionStorage.getItem(tokenResponseSessionStorageKey);
    if (json == null) {
      return null;
    }

    const tokenResponse = JSON.parse(json);
    if (tokenResponse?.expires_at == null) {
      return tokenResponse;
    }

    // Given up a little before it is actually out, so that a token cannot run
    // out somewhere between being read here and arriving at the server.
    if (Date.now() < tokenResponse.expires_at - tokenExpiryMargin) {
      return tokenResponse;
    }
    OidcStorage.tokenResponse = null;
    return null;
  }

  /**
   * @param value {OidcFlowState|null}
   */
  static set oidcFlowState(value) {
    setOrRemove(oidcFlowStateSessionStorageKey, value == null ? null : JSON.stringify(value));
  }

  /**
   * @return {OidcFlowState|null}
   */
  static get oidcFlowState() {
    const json = sessionStorage.getItem(oidcFlowStateSessionStorageKey);
    if (json == null) {
      return null;
    }
    return JSON.parse(json);
  }

  /**
   * @param value {string|null}
   */
  static set refreshToken(value) {
    setOrRemove(refreshTokenSessionStorageKey, value);
  }

  /**
   * @return {string|null}
   */
  static get refreshToken() {
    return sessionStorage.getItem(refreshTokenSessionStorageKey);
  }
}

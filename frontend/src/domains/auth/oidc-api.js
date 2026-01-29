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
          sessionStorage.removeItem(oidcFlowStateSessionStorageKey);
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

  async getUserInfo() {
    const accessToken = await this.getActiveAccessToken();
    if (accessToken == null)
      throw 'failed to get access-token to getUserInfo';
    return await OidcApi.callUserInfoEndpoint(
      this._oidcConfig.userInfoEndpoint,
      accessToken,
      this._oidcConfig.rolesKey
    );
  }

  async canBeReached() {
    const response = await fetch(this._oidcConfig.healthzEndpoint);
    return response.ok;
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

    if (response.status >= 500) {
      throw `failed to get access-token (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to get access-token: ${response.status} ${response.statusText}: ${await response.text()}`;
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

    if (response.status >= 500) {
      throw `failed to get user info (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to get user info: ${response.status} ${response.statusText}: ${await response.text()}`;
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
  return window.CryptoJS.SHA256(input).toString(CryptoJS.enc.Hex);
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
      .replace(/\//g, '-')
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
   * @param name {string}
   * @param subject {string}
   * @param roles {Object}
   */
  constructor(name, subject, roles) {
    this.name = name;
    this.subject = subject;
    this.roles = roles;
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
    return new UserInfoResponse(
      response['name'] + '',
      response['sub'] + '',
      response[rolesKey]
    );
  }
}

const oidcFlowStateSessionStorageKey = 'auth_oidc_flow_state';
const tokenResponseSessionStorageKey = 'auth_token_response';
const refreshTokenLocalStorageKey = 'auth_refresh_token';

class OidcStorage {

  /**
   * @param value {TokenResponse|null}
   */
  static set tokenResponse(value) {
    sessionStorage.setItem(tokenResponseSessionStorageKey, JSON.stringify(value))
    if (value != null && value.expires_in !== 0) {
      setTimeout(function () {
        const tokenResponse = OidcStorage.tokenResponse;
        if (tokenResponse != null && tokenResponse.access_token === value.access_token) {
          OidcStorage.tokenResponse = null;
        }
      }, value.expires_in);
    }
  }

  /**
   * @return {TokenResponse|null}
   */
  static get tokenResponse() {
    const json = sessionStorage.getItem(tokenResponseSessionStorageKey);
    if (json == null) {
      return null;
    }
    return JSON.parse(json);
  }

  /**
   * @param value {OidcFlowState|null}
   */
  static set oidcFlowState(value) {
    sessionStorage.setItem(oidcFlowStateSessionStorageKey, JSON.stringify(value))
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
    sessionStorage.setItem(refreshTokenLocalStorageKey, value);
  }

  /**
   * @return {string|null}
   */
  static get refreshToken() {
    return sessionStorage.getItem(refreshTokenLocalStorageKey);
  }
}

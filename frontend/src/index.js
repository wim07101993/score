import {authorizationCodeQueryParamName, authorize} from './auth.js';
import {authConfig} from './auth.config.js';

const urlParams = new URLSearchParams(window.location.search);

await authorize(
  authConfig.clientId,
  authConfig.redirectUri,
  authConfig.authorizationEndpoint,
  authConfig.tokenEndpoint,
  urlParams.get(authorizationCodeQueryParamName),
);

// remove the authorization code from the url params
window.history.replaceState(null, null, window.location.pathname);

import {AuthConfig} from "./data/auth.js";
import {ApiConfig} from "./data/scores-api.js";

export const authConfig = new AuthConfig(
  '342055608129748996',
  new URL('https://score.wvl.app/'),
  new URL('https://auth.wvl.app/oauth/v2/authorize'),
  new URL('https://auth.wvl.app/oauth/v2/token'),
  new URL('https://auth.wvl.app/oidc/v1/userinfo'),
  'urn:zitadel:iam:org:project:roles'
);

export const apiConfig = new ApiConfig(
  new URL('https://score-api.wvl.app')
);

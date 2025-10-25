import {AuthConfig} from "./data/auth.js";
import {ApiConfig} from "./data/scores-api.js";

export const authConfig = new AuthConfig(
  '340579470668791812',
  new URL('http://localhost:3000/'),
  new URL('https://auth.wvl.app/oauth/v2/authorize'),
  new URL('https://auth.wvl.app/oauth/v2/token'),
  new URL('https://auth.wvl.app/oidc/v1/userinfo'),
  'urn:zitadel:iam:org:project:roles'
);

export const apiConfig = new ApiConfig(
  new URL('http://plop.home:7001')
);

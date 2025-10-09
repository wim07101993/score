import {setAuthConfig} from "./data/auth/auth.js";

setAuthConfig({
  clientId: '340579470668791812',
  redirectUri: new URL('http://localhost:3000/'),
  authorizationEndpoint: new URL('https://auth.wvl.app/oauth/v2/authorize'),
  tokenEndpoint: new URL('https://auth.wvl.app/oauth/v2/token')
});

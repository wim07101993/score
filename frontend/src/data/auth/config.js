export const authConfig = {
  clientId: '321160767120408579',
  redirectUri: new URL('http://localhost:3000/'),
  authorizationEndpoint: new URL('http://localhost:7003/oauth/v2/authorize'),
  tokenEndpoint: new URL('http://localhost:7003/oauth/v2/token')
};

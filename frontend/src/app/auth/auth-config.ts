import { AuthConfig } from 'angular-oauth2-oidc';

export const authCodeFlowConfig: AuthConfig = {
    issuer: 'http://localhost:7003',
    redirectUri: 'http://localhost:4200',
    clientId: '309755485458857987',
    responseType: 'code',
    scope: 'openid profile email offline_access api',
    showDebugInformation: true,
};

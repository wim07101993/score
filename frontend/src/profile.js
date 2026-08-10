import {App} from "./app.js";
import {OidcStorage} from "./domains/auth/oidc-api.js";

/**
 * What this app has been told about the user, and by whom.
 *
 * Every page decides what to show from the roles the provider sent — a page
 * that shows nothing is a page that was told nothing, and until now there was
 * nowhere to see what that was. So this shows the answer as it came back rather
 * than what this app made of it: the claim the roles were looked for under, the
 * claims that actually arrived, whether they came from the provider or from the
 * copy this device kept, and which version of the app is asking.
 */

const failureSection = document.getElementById('failure-section');
const failure = document.getElementById('failure');

const userList = document.getElementById('user');
const userSource = document.getElementById('user-source');
const rolesList = document.getElementById('roles');
const rolesExplanation = document.getElementById('roles-explanation');
const claims = document.getElementById('claims');
const configList = document.getElementById('config');
const storageList = document.getElementById('storage');

const refreshButton = document.getElementById('refresh-button');
const signInAgainButton = document.getElementById('sign-in-again-button');
const updateAppButton = document.getElementById('update-app-button');

const app = new App('config.json');

// ----------------------------------------------------------------------------
// WRITING A LIST
// ----------------------------------------------------------------------------

/**
 * @param list {HTMLElement}
 * @param rows {{term: string, value: *, absent?: string, id?: string}[]}
 *   `value` is shown as it is; `absent` is what to say instead when there is no
 *   value, which is not the same as an empty one; `id` names the row for
 *   whoever fills it in later.
 */
function _fill(list, rows) {
  list.replaceChildren();
  for (const row of rows) {
    const term = document.createElement('dt');
    term.innerText = row.term;

    const value = document.createElement('dd');
    if (row.id != null) {
      value.id = row.id;
    }
    if (row.value == null || row.value === '') {
      value.innerText = row.absent ?? 'not sent';
      value.className = 'absent';
    } else {
      value.innerText = `${row.value}`;
    }

    list.append(term, value);
  }
}

/**
 * @param yes {boolean}
 * @return {string}
 */
function _yesNo(yes) {
  return yes ? 'yes' : 'no';
}

// ----------------------------------------------------------------------------
// WHAT IS SHOWN
// ----------------------------------------------------------------------------

function _drawUser() {
  const user = app.user;

  _fill(userList, [
    {term: 'Name', value: user?.name},
    {term: 'Email', value: user?.email},
    {term: 'Subject', value: user?.subject, absent: 'not signed in'},
  ]);

  if (user == null) {
    userSource.innerText = 'Nobody is signed in on this device.';
    return;
  }
  userSource.innerText = app.userIsFromThisDevice
    ? 'The provider could not be reached, so this is the copy this device kept'
      + ' the last time it could ask. Your roles may have changed since.'
    : 'Asked of the provider just now.';
}

function _drawRoles() {
  const user = app.user;
  const rolesKey = user?.rolesKey ?? app.config?.oidc?.rolesKey;

  _fill(rolesList, [
    {term: 'See scores and sets', value: _yesNo(user?.isScoreViewer === true)},
    {term: 'Upload scores', value: _yesNo(user?.isScoreEditor === true)},
    {term: 'Roles claim', value: rolesKey},
    {
      term: 'Roles found',
      value: user?.roles == null ? null : Object.keys(user.roles).join(', '),
      absent: `no claim named "${rolesKey}" in the answer`,
    },
  ]);

  if (user?.roles == null) {
    const sent = user?.claims == null ? [] : Object.keys(user.claims);
    rolesExplanation.innerText = sent.length === 0
      ? 'The provider sent no claims this app could read.'
      : `The roles are read out of the claim named "${rolesKey}", and the answer`
      + ` does not have one. What it does have: ${sent.join(', ')}.`;
    return;
  }

  rolesExplanation.innerText = user.isScoreViewer
    ? ''
    : `The claim "${rolesKey}" is there, but "score_viewer" is not one of the roles in it.`;
}

function _drawClaims() {
  claims.innerText = app.user?.claims == null
    ? 'Nothing was read from the provider on this device.'
    : JSON.stringify(app.user.claims, null, 2);
}

async function _drawConfig() {
  const oidc = app.config?.oidc;
  const api = app.config?.api;

  _fill(configList, [
    {term: 'Client id', value: oidc?.clientId},
    {term: 'Redirect uri', value: oidc?.redirectUri},
    {term: 'Authorization endpoint', value: oidc?.authorizationEndpoint},
    {term: 'Token endpoint', value: oidc?.tokenEndpoint},
    {term: 'User-info endpoint', value: oidc?.userInfoEndpoint},
    {term: 'Provider healthz', value: oidc?.healthzEndpoint},
    {term: 'Provider reachable', value: 'asking…', id: 'provider-reachable'},
    {term: 'API', value: api?.baseUrl},
    {term: 'API reachable', value: 'asking…', id: 'api-reachable'},
    {term: 'Access token', value: OidcStorage.tokenResponse?.access_token == null ? null : 'held'},
    {term: 'Refresh token', value: OidcStorage.refreshToken == null ? null : 'held'},
  ]);

  // Both of these are a round trip, and the rest of the page is worth showing
  // before they come back.
  const [providerReachable, apiReachable] = await Promise.all([
    app.oidcApi?.canBeReached() ?? false,
    app.scoresApi?.canBeReached() ?? false,
  ]);

  _write('provider-reachable', _yesNo(providerReachable));
  _write('api-reachable', _yesNo(apiReachable));
}

/**
 * @param id {string}
 * @param value {string}
 */
function _write(id, value) {
  const element = document.getElementById(id);
  if (element == null) {
    return;
  }
  element.innerText = value;
  element.className = '';
}

async function _drawStorage() {
  const pending = app.setRepository == null
    ? []
    : app.setRepository.sets.filter((set) => set.pending_change != null);

  const rows = [
    {term: 'Scores', value: `${app.scoreRepository?.scores.length ?? 0}`},
    {term: 'Sets', value: `${app.setRepository?.sets.length ?? 0}`},
    {
      term: 'Sets not sent yet',
      value: pending.length === 0
        ? 'none'
        : `${pending.length}: ${pending.map((set) => set.title || 'untitled').join(', ')}`,
    },
    {
      term: 'Served by a worker',
      value: _yesNo(navigator.serviceWorker?.controller != null),
    },
  ];

  if (typeof caches !== 'undefined') {
    const names = await caches.keys();
    rows.push({term: 'Cached app versions', value: names.join(', '), absent: 'none'});
  }

  if (navigator.storage?.estimate != null) {
    const {usage, quota} = await navigator.storage.estimate();
    rows.push({
      term: 'Room used',
      value: `${_megabytes(usage)} MB of ${_megabytes(quota)} MB`,
    });
  }

  _fill(storageList, rows);
}

/**
 * @param bytes {number|undefined}
 * @return {string}
 */
function _megabytes(bytes) {
  return ((bytes ?? 0) / (1024 * 1024)).toFixed(1);
}

async function _draw() {
  _drawUser();
  _drawRoles();
  _drawClaims();
  await Promise.all([_drawConfig(), _drawStorage()]);
}

// ----------------------------------------------------------------------------
// STARTING OVER
// ----------------------------------------------------------------------------

async function onRefreshClicked() {
  refreshButton.disabled = true;
  try {
    await app.updateAuth();
    await _draw();
  } catch (error) {
    console.error('failed to ask the provider again', error);
    _showFailure(error);
  } finally {
    refreshButton.disabled = false;
  }
}

function onSignInAgainClicked() {
  app.forgetUser();
  window.location = '/';
}

/**
 * Throws away every cached copy of the app and lets go of the worker serving
 * them, so that the next load is fetched.
 *
 * A page is served from a cache before it is served from the network, which is
 * what makes the app work with no network at all — and also what keeps a
 * version that has been replaced on screen. This is the way out of that when it
 * happens.
 */
async function onUpdateAppClicked() {
  updateAppButton.disabled = true;
  try {
    if (typeof caches !== 'undefined') {
      const names = await caches.keys();
      await Promise.all(names.map((name) => caches.delete(name)));
    }
    const registrations = await navigator.serviceWorker?.getRegistrations() ?? [];
    await Promise.all(registrations.map((registration) => registration.unregister()));
  } catch (error) {
    console.error('failed to throw away the cached app', error);
  }
  window.location.reload();
}

/**
 * @param error {*}
 */
function _showFailure(error) {
  failureSection.hidden = false;
  failure.innerText = `${error?.stack ?? error}`;
}

async function main() {
  // Every button here is one to reach for when the app is not working, so they
  // are wired up before anything that can fail.
  refreshButton.addEventListener('click', onRefreshClicked);
  signInAgainButton.addEventListener('click', onSignInAgainClicked);
  updateAppButton.addEventListener('click', onUpdateAppClicked);

  try {
    await app.initialize();
  } catch (error) {
    console.error('failed to initialize the app', error);
    _showFailure(error);
  }

  await _draw();
}

await main();

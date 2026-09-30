'use strict';

// The app, kept on this device so that it opens where there is no network.
//
// A score is read on a stage and a set is edited at a gig, and both are where
// there is no signal. What the app knows — the scores, the sets, the edits it
// still owes the server — it keeps itself, in IndexedDB. This keeps the app
// that reads it: every file of the build is fetched once, while there is a
// network, and answered from here from then on.
//
// It is at the address the app before this one registered its own worker at,
// so a browser that still runs that one is handed this one at its next update
// check, rather than being left on the old app.

// Written in by tool/precache.dart once `flutter build web` has run: every file
// of the build that is kept, with a hash of what is in it. Left as they are —
// on a development server, or a build the tool was not run on — there is
// nothing to keep, and the worker stands aside.
const RESOURCES = {};
const VERSION = '';

const CACHE_PREFIX = 'score-app-';
const CACHE_NAME = CACHE_PREFIX + VERSION;

/// Where the hashes a cache was filled from are kept, so that the next version
/// fetches only what changed rather than the whole app again.
const MANIFEST = '__resources__';

/// The one file that is not the app but what the app is pointed at. It is kept
/// like everything else, but asked of the server first every time, so that it
/// can be changed there without building anything and the next start already
/// uses it — a start on the old one would be a start against an API or a
/// client that may be gone. Only when the server does not answer in time is
/// the kept copy used.
const CONFIG = 'assets/assets/config.json';

/// How long the config is waited for before the kept copy is used instead.
const CONFIG_PATIENCE_MS = 3000;

/// How many files are fetched at once while the app is being kept. A phone on
/// a venue's wifi is better served by a queue than by every file at once.
const AT_ONCE = 6;

const scope = self.registration.scope;
const scopePath = new URL(scope).pathname;
const urlOf = (path) => new URL(path, scope).toString();

self.addEventListener('install', (event) => {
  event.waitUntil(install());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(activate());
});

self.addEventListener('fetch', (event) => {
  if (!VERSION || event.request.method !== 'GET') {
    return;
  }
  const path = pathOf(event.request.url);
  if (path == null) {
    // Not the app: the API and the identity provider answer about a moment,
    // and what they said is kept by the app, where it knows when it was said.
    return;
  }

  if (path === CONFIG) {
    event.respondWith(freshOrKept(path));
  } else if (Object.prototype.hasOwnProperty.call(RESOURCES, path)) {
    event.respondWith(kept(event.request, path));
  } else if (event.request.mode === 'navigate') {
    // Every address of the app is the app — which page it opens on is the
    // app's to work out, the way it is on the server (`try_files … /index.html`
    // in web.nginx.conf). That includes the provider sending the browser back
    // with a code, and the addresses of the app this one replaced.
    event.respondWith(kept(event.request, 'index.html'));
  }
  // Anything else the build does not have is left to the network, the way it
  // would be without a worker.
});

/// Fetches and keeps this version of the app. All of it or none of it: an app
/// put together from two versions is an app that does not start, so a version
/// that could not be kept whole is not taken on, and the one before it goes on
/// being answered with. The browser tries again at its next update check.
async function install() {
  if (!VERSION) {
    await self.skipWaiting();
    return;
  }

  const cache = await caches.open(CACHE_NAME);
  const before = await keptBefore();
  const paths = Object.keys(RESOURCES);
  let next = 0;
  const fetchTheRest = async () => {
    while (next < paths.length) {
      const path = paths[next++];
      await keep(cache, before, path);
    }
  };
  await Promise.all(Array.from({length: AT_ONCE}, fetchTheRest));
  await cache.put(urlOf(MANIFEST), new Response(JSON.stringify(RESOURCES)));

  // Taking over at once rather than when every tab of the app has closed: an
  // app installed on a tablet is hardly ever closed, and it should not take
  // that for a release to reach it. A page already open goes on with what it
  // loaded; the next one it opens is the new version.
  await self.skipWaiting();
}

/// One file of this version: out of the version before when it has not
/// changed, and from the server otherwise.
async function keep(cache, before, path) {
  const url = urlOf(path);
  if (before != null && before.resources[path] === RESOURCES[path]) {
    const held = await before.cache.match(url);
    if (held != null) {
      await cache.put(url, held);
      return;
    }
  }
  // Past the browser's own cache: what is wanted is this version of the file,
  // not a copy the browser held on to from before it.
  const response = await fetch(new Request(url, {cache: 'reload'}));
  if (!response.ok) {
    throw new Error(`${path} could not be kept: ${response.status}`);
  }
  const body = await response.arrayBuffer();
  // A server halfway through a deploy answers from the version before, and one
  // that does not have the file answers with index.html, both with a 200. Kept,
  // either would be served as this version for as long as the file does not
  // change. The config is the exception: it may be changed on the server
  // without building anything.
  if (path !== CONFIG && (await sha256Of(body)) !== RESOURCES[path]) {
    throw new Error(`${path} is not the one of this version`);
  }
  await cache.put(url, new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  }));
}

async function sha256Of(body) {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', body));
  return Array.from(digest, (b) => b.toString(16).padStart(2, '0')).join('');
}

/// The version of the app kept before this one, and what it was made of.
async function keptBefore() {
  for (const name of await caches.keys()) {
    if (!name.startsWith(CACHE_PREFIX) || name === CACHE_NAME) {
      continue;
    }
    const cache = await caches.open(name);
    const manifest = await cache.match(urlOf(MANIFEST));
    if (manifest == null) {
      continue;
    }
    try {
      return {cache, resources: await manifest.json()};
    } catch (_) {
      // A version that was never kept whole is no version to copy from.
    }
  }
  return null;
}

async function activate() {
  // Every other cache on this origin is an earlier version of this app, or the
  // app before it — a copy of the whole app each, which nothing reads any more.
  for (const name of await caches.keys()) {
    if (name !== CACHE_NAME) {
      await caches.delete(name);
    }
  }
  if (!VERSION) {
    await self.registration.unregister();
    return;
  }
  // Serving the pages that are already open too, so that a page opened before
  // the app was kept is itself kept working when the network goes.
  await self.clients.claim();
}

/// A file of the app, from what is kept. Only when the browser has thrown that
/// away behind the app's back is the network asked instead.
async function kept(request, path) {
  const cache = await caches.open(CACHE_NAME);
  const held = await cache.match(urlOf(path));
  if (held != null) {
    return held;
  }
  try {
    return await fetch(request);
  } catch (error) {
    return Response.error();
  }
}

/// The config as the server has it now, kept for next time; or the kept copy,
/// when the server does not answer or does not answer in time.
async function freshOrKept(path) {
  const cache = await caches.open(CACHE_NAME);
  const url = urlOf(path);
  const fresh = fetch(new Request(url, {cache: 'no-cache'})).then(
    async (response) => {
      if (!response.ok) {
        throw new Error(`the config could not be read: ${response.status}`);
      }
      await cache.put(url, response.clone());
      return response;
    },
  );
  const tooLate = new Promise((_, reject) =>
    setTimeout(() => reject(new Error('the config took too long')),
      CONFIG_PATIENCE_MS));
  try {
    return await Promise.race([fresh, tooLate]);
  } catch (_) {
    fresh.catch(() => {});
    const held = await cache.match(url);
    return held != null ? held : fresh;
  }
}

/// Where in the build [url] is, or null when it is not in the app at all.
function pathOf(url) {
  const parsed = new URL(url);
  if (parsed.origin !== self.location.origin) {
    return null;
  }
  let path;
  try {
    path = decodeURIComponent(parsed.pathname);
  } catch (_) {
    return null;
  }
  if (!path.startsWith(scopePath)) {
    return null;
  }
  return path.substring(scopePath.length);
}

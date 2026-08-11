// Bump this whenever a cached file changes: fetches are answered from the cache
// before the network, so an installed client goes on serving the previous
// version of every file below until the cache is a different one.
const cacheName = "score-cache-v0.13";
// A directory is listed by the url a page is actually asked for, never as
// "<dir>/index.html": the file server answers that spelling with a redirect to
// the directory, and a redirect is not something that can be cached or handed
// to a navigation.
const cacheUrls = [
  "/",
  "/assets/icons/artist.svg",
  "/assets/icons/instrument.svg",
  "/assets/icons/tag.svg",
  "/components/score-card.component.js",
  "/components/set-card.component.js",
  "/data/helper-functions.js",
  "/data/translations.js",
  "/domains/auth/oidc-api.js",
  "/domains/scores/api.js",
  "/domains/scores/database.js",
  "/domains/scores/musicxml-view.js",
  "/domains/scores/osmd-score-view.js",
  "/domains/scores/repository.js",
  "/domains/scores/score-view.js",
  "/domains/scores/storage.js",
  "/domains/sets/api.js",
  "/domains/sets/database.js",
  "/domains/sets/repository.js",
  "/packages/lit-core.3.3.3.min.js",
  "/packages/open_sheet_music_display.1.8.9.min.js",
  "/scores/detail.css",
  "/scores/detail.html",
  "/scores/detail.js",
  "/scores/perform.css",
  "/scores/perform.html",
  "/scores/perform.js",
  "/sets/",
  "/sets/detail.css",
  "/sets/detail.html",
  "/sets/detail.js",
  "/sets/index.css",
  "/sets/index.js",
  "/app.js",
  "/config.json",
  "/index.css",
  "/index.js",
  "/profile.css",
  "/profile.html",
  "/profile.js",
  "/theme.css",
];

let config;

self.addEventListener("install", (event) => {
  // waitUntil, or installing is over before a single file has been cached and
  // the worker counts as installed whether or not it has anything to serve.
  event.waitUntil((async () => {
    try {
      const cache = await caches.open(cacheName);
      await cache.addAll(cacheUrls);
    } catch (error) {
      console.error("Service Worker installation failed:", error);
    }
    // Without this, a worker that has been installed waits for every tab of the
    // app to be closed before it takes over, and until it does, the worker it
    // is replacing goes on answering from the cache it was built with. Bumping
    // the cache name is then no help at all: the new cache is filled and left
    // untouched while the previous version of every file keeps being served.
    await self.skipWaiting();
  })());
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    // The caches of every earlier version. Nothing reads them any more, and
    // they are a copy of the whole app each.
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name !== cacheName)
      .map((name) => caches.delete(name)));

    // Take over the pages that are already open rather than only the ones
    // opened from here on.
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", (event) => {
  event.respondWith(respondTo(event.request));
});

// Whatever this answers is what the browser shows, so it has to answer with a
// response no matter what goes wrong: a promise that rejects, or one that
// resolves to nothing, is a network error, and a navigation that ends in one is
// the browser's "this site can't be reached" page rather than the app.
async function respondTo(request) {
  if (config == null) {
    try {
      await fetchConfig();
    } catch (error) {
      // Without the config there is no telling the api and the idp from the app
      // itself, and guessing wrong would cache an answer that must not be
      // cached. This one goes straight to the network.
      console.error(error);
      return await fetchOrError(request);
    }
  }

  // don't cache anything from the idp, and nothing from the API either.
  //
  // What the API answers is an answer about a moment: a listing says what
  // changed inside the window it was asked about, and matching it by url
  // with the query ignored would hand every later sync the first one's
  // answer. The app that asks is what is cached here; what it is told is
  // kept by the app itself, in a database that knows when it was told.
  const url = new URL(request.url);
  const oidcHost = new URL(config.oidc.healthzEndpoint);
  if (request.method !== 'GET'
    || url.host === oidcHost.host
    || url.href.startsWith(new URL(config.api.baseUrl).href)
    || url.pathname.endsWith('healthz')) {
    return await fetchOrError(request);
  }

  const cache = await caches.open(cacheName);

  const cachedResponse = await cache.match(request, {ignoreSearch: true});
  if (cachedResponse) {
    return cachedResponse;
  }

  let response;
  try {
    response = await fetch(request);
  } catch (error) {
    // Offline, and this url has never been cached. The app shell is the closest
    // thing to an answer there is.
    console.log("Fetch failed: ", error);
    return await cache.match("/") ?? Response.error();
  }

  // A redirect is not a document. A navigation is fetched with its redirect
  // mode set to manual, so what comes back for one is opaque: the cache refuses
  // to store it, and storing a followed redirect would be worse still, since
  // handing a redirected response back to a navigation is a network error.
  // Pass it along and let the browser go where it says.
  if (response.status !== 200 || response.redirected) {
    return response;
  }

  await cache.put(request, response.clone());
  return response;
}

async function fetchOrError(request) {
  try {
    return await fetch(request);
  } catch (error) {
    console.log("Fetch failed: ", error);
    return Response.error();
  }
}

async function fetchConfig() {
  const response = await fetch('config.json');
  if (response.status >= 500) {
    throw `failed to fetch config (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
  } else if (response.status >= 400) {
    throw `failed to fetch config:  ${response.status} ${response.statusText}: ${await response.text()}`;
  }
  config = await response.json();
}

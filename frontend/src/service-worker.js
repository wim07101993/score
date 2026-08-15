// Bump this whenever a cached file changes: fetches are answered from the cache
// before the network, so an installed client goes on serving the previous
// version of every file below until the cache is a different one.
//
// It is also the whole of what an installed app has to go on. Clients ask this
// file for a newer version whenever they can reach the server — see
// `domains/updates/app-update.js` — and what they compare is the bytes of this
// file. A release that changes a page and leaves this line alone is a release
// no device already carrying the app will ever see.
const cacheName = "score-cache-v0.15";
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
  "/domains/scores/pinch-zoom.js",
  "/domains/scores/repository.js",
  "/domains/scores/score-view.js",
  "/domains/scores/storage.js",
  "/domains/sets/api.js",
  "/domains/sets/database.js",
  "/domains/sets/repository.js",
  "/domains/settings/settings.js",
  "/domains/settings/sheet-palette.js",
  "/domains/updates/app-update.js",
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
  "/settings.css",
  "/settings.html",
  "/settings.js",
  "/theme-boot.js",
  "/theme.css",
];

let config;

// What a page sends to say "fetch whatever of the app you have not got". The
// page's half of this is `domains/updates/app-update.js`, and the two have to
// agree on the word.
const fillInMessage = "fill-in-what-is-missing";

self.addEventListener("install", (event) => {
  // waitUntil, or installing is over before a single file has been cached and
  // the worker counts as installed whether or not it has anything to serve.
  event.waitUntil((async () => {
    const cache = await caches.open(cacheName);
    await fetchIntoCache(cache, cacheUrls);
    // Without this, a worker that has been installed waits for every tab of the
    // app to be closed before it takes over, and until it does, the worker it
    // is replacing goes on answering from the cache it was built with. Bumping
    // the cache name is then no help at all: the new cache is filled and left
    // untouched while the previous version of every file keeps being served.
    await self.skipWaiting();
  })());
});

// A page has been opened, which is a chance to make good whatever this device
// is missing. Nothing about it is the page's business beyond the asking: the
// list and the cache are this file's.
self.addEventListener("message", (event) => {
  if (event.data?.type === fillInMessage) {
    event.waitUntil(fillInWhatIsMissing());
  }
});

/**
 * Fetches whatever of the app is not on this device yet.
 *
 * Installing is one chance to cache the app and it is the worst one there is:
 * it happens once, on whatever network the first visit was made on, and
 * anything that failed then stayed failed until the next release. So every page
 * load asks again, and only what is actually missing is fetched — on a device
 * that has the whole app, which is nearly always, this is a look in a cache and
 * nothing else.
 *
 * @return {Promise<number>} how many files were fetched
 */
async function fillInWhatIsMissing() {
  const cache = await caches.open(cacheName);

  const missing = [];
  for (const url of cacheUrls) {
    if (await cache.match(url, {ignoreSearch: true}) == null) {
      missing.push(url);
    }
  }
  if (missing.length === 0) {
    return 0;
  }

  console.log(`${missing.length} of the app's ${cacheUrls.length} files are not on this device; fetching them`);
  return await fetchIntoCache(cache, missing);
}

/**
 * Fetches each of `urls` and keeps what comes back.
 *
 * Each file is its own question. This was `cache.addAll`, which is all or
 * nothing: one url that answered 404, or one fetch that gave out on a phone
 * halfway up a stairwell, and not a single file was cached — while the worker
 * went on to activate, delete the previous version's cache and take over
 * anyway. An app served by a worker with an empty cache behind it is an app
 * that only works online, which is the one thing this file exists to prevent.
 *
 * What fails is named rather than swallowed, and made good the next time a page
 * is opened.
 *
 * @param cache {Cache}
 * @param urls {string[]}
 * @return {Promise<number>} how many of them are now cached
 */
async function fetchIntoCache(cache, urls) {
  const refused = [];

  await Promise.all(urls.map(async (url) => {
    try {
      // Past the browser's own cache. What is being asked for is the newest
      // version of the app, and a copy the browser is holding on to from before
      // the release is exactly what this is here to get out from under.
      const response = await fetch(new Request(url, {cache: "reload"}));
      if (!response.ok) {
        refused.push(`${url} (${response.status})`);
        return;
      }
      await cache.put(url, response);
    } catch (error) {
      refused.push(`${url} (${error})`);
    }
  }));

  if (refused.length > 0) {
    console.error(
      `${refused.length} of ${urls.length} files of the app were not cached:`,
      refused,
    );
  }
  return urls.length - refused.length;
}

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

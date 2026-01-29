const cacheName = "score-cache-v1";
const cacheUrls = [
  "/",
  "/assets/artist.svg",
  "/assets/instrument.svg",
  "/assets/tag.svg",
  "/components/score-list-item.component.js",
  "/data/database.js",
  "/data/html-functions.js",
  "/data/oidc.js",
  "/data/scores-api.js",
  "/data/storage.js",
  "/data/translations.js",
  "/packages/open_sheet_music_display.1.8.9.min.js",
  "/scores/detail.css",
  "/scores/detail.html",
  "/scores/detail.js",
  "/config.js",
  "/globals.js",
  "/index.css",
  "/index.html",
  "/index.js",
  "/score-domain.js",
  "/theme.css",
];

let config;

self.addEventListener("install", async (event) => {
  try {
    const cache = await caches.open(cacheName);
    await cache.addAll(cacheUrls);
  } catch (error) {
    console.error("Service Worker installation failed:", error);
  }
});

self.addEventListener("fetch", (event) => {
  event.respondWith(
    (async () => {
      if (config == null) {
        await fetchConfig();
      }
      // don't cache anything from the idp.
      const url = new URL(event.request.url);
      const oidcHost = new URL(config.oidc.healthzEndpoint);
      if (url.host === oidcHost.host || url.pathname.endsWith('healthz')) {
        return await fetch(event.request);
      }

      const cache = await caches.open(cacheName);

      try {
        const cachedResponse = await cache.match(event.request, {ignoreSearch: true});
        if (cachedResponse) {
          return cachedResponse;
        }

        const fetchResponse = await fetch(event.request);
        if (fetchResponse) {
          await cache.put(event.request, fetchResponse.clone());
          return fetchResponse;
        }
      } catch (error) {
        console.log("Fetch failed: ", error);
        return await cache.match("index.html");
      }
    })()
  );
});

async function fetchConfig() {
  const response= await fetch('config.json');
  if (response.status >= 500) {
    throw `failed to fetch config (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
  } else if (response.status >= 400) {
    throw `failed to fetch config:  ${response.status} ${response.statusText}: ${await response.text()}`;
  }
  config = await response.json();
}

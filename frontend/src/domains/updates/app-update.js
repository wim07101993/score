/**
 * Keeping the app itself up to date.
 *
 * Every file of this app is served out of a cache before it is served out of
 * the network, which is what makes it work at a gig with no signal at all — and
 * also what keeps a version that has been replaced on screen for as long as
 * nobody clears anything. So the newest version has to be gone looking for
 * rather than waited for: whenever this device can reach the server, it asks
 * whether there is a newer worker, and the worker fills a new cache and takes
 * over the moment it has one.
 *
 * Nothing here is a download the reader has to agree to. A player standing on a
 * stage is not going to read a banner about versions.
 */

/**
 * Absolute, and not relative to the page asking: `/scores/perform.html` asking
 * for "service-worker.js" would be asking for a file that is not there, and a
 * worker registered from `/scores/` could not serve the pages above it anyway.
 *
 * @type {string}
 */
const workerUrl = '/service-worker.js';

/**
 * How often it is worth asking. Coming back to a tab, plugging the wifi back
 * in and opening a page are all "the server may be reachable now", and on a
 * phone they happen in threes.
 *
 * @type {number}
 */
const leastTimeBetweenAsking = 5 * 60 * 1000;

/** Registering twice on one page would ask twice and listen twice. */
let watching = false;

/** A reload that is already happening. @type {boolean} */
let reloading = false;

/**
 * Registers the worker that serves this app, and keeps asking the server for a
 * newer one for as long as the page is open.
 *
 * @param options {{reloadWhenReplaced?: boolean}} `reloadWhenReplaced` is for
 *   pages where a reload costs the reader nothing — a list, a settings page. It
 *   is off by default, because the pages where it is not free are the ones that
 *   matter: a score being played from would lose its place, and a set being
 *   edited would lose whatever has not been written yet. Those pages get the
 *   new version the next time they are opened, which is soon enough.
 * @return {Promise<ServiceWorkerRegistration|null>}
 */
export async function keepAppUpToDate(options = {}) {
  const {reloadWhenReplaced = false} = options;

  if (typeof navigator === 'undefined' || navigator.serviceWorker == null) {
    return null;
  }
  if (watching) {
    return null;
  }
  watching = true;

  // A page that was already being served by a worker and is then handed to a
  // different one has just been handed a newer app. A page that had no worker
  // at all and gets one has simply had this app installed on it, and reloading
  // for that would be reloading the first visit.
  const wasBeingServed = navigator.serviceWorker.controller != null;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    console.log('a newer version of the app has taken over');
    if (!reloadWhenReplaced || !wasBeingServed || reloading) {
      return;
    }
    reloading = true;
    window.location.reload();
  });

  let registration;
  try {
    registration = await navigator.serviceWorker.register(workerUrl, {scope: '/'});
    console.log('Service Worker registered with scope:', registration.scope);
  } catch (error) {
    console.error('Service Worker registration failed:', error);
    return null;
  }

  let lastAsked = 0;
  const ask = async () => {
    // Asking with the aeroplane mode on is a round trip that cannot go
    // anywhere, and the answer would be the same either way.
    if (navigator.onLine === false) {
      return;
    }
    const now = Date.now();
    if (now - lastAsked < leastTimeBetweenAsking) {
      return;
    }
    lastAsked = now;
    try {
      await registration.update();
    } catch (error) {
      // The server could not be reached. Nothing is wrong with the app; there
      // is simply nothing to say about it right now, and the next chance to ask
      // should not be held off for having tried.
      lastAsked = 0;
      console.log('could not ask for a newer version of the app', error);
    }
  };

  // Every one of these is a moment at which the server may have become
  // reachable, which is the whole of what this waits for.
  globalThis.addEventListener?.('online', ask);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      ask();
    }
  });
  await ask();

  return registration;
}

/**
 * Throws away every cached copy of the app and lets go of the workers serving
 * them, so that the next load is fetched from the server.
 *
 * This is the way out when the app is behaving like a version that has been
 * replaced and asking for a newer one has not helped — a worker that failed
 * half way through installing, a cache with a file in it that never finished
 * arriving. It is not the usual way an update arrives; that is
 * {@link keepAppUpToDate}, and it needs nobody to press anything.
 *
 * @return {Promise<void>}
 */
export async function reinstallApp() {
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
  reloading = true;
  // With nothing left to serve it, this load is the network's to answer, and
  // the worker that registers on the way back fills a cache from scratch.
  window.location.reload();
}

/**
 * Which versions of the app this device is holding on to.
 *
 * There is normally one: a worker deletes every cache but its own the moment it
 * takes over. Two means one has been installed and has not taken over yet.
 *
 * @return {Promise<string[]>}
 */
export async function installedVersions() {
  if (typeof caches === 'undefined') {
    return [];
  }
  try {
    return await caches.keys();
  } catch (error) {
    console.error('failed to read what is cached', error);
    return [];
  }
}

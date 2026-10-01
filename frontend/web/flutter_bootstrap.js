{{flutter_js}}
{{flutter_build_config}}

// The app's own service worker rather than Flutter's: the one Flutter builds
// only unregisters itself, and it would replace this one at every start. See
// web/service-worker.js for what this one keeps, and tool/precache.dart for
// how it learns what that is.
//
// Only for a build of the app, not for `flutter run`: a development server
// answered out of a cache is a development server that never changes.
const isADevelopmentBuild = _flutter.buildConfig.builds.some(
  (build) => build.compileTarget === 'dartdevc',
);
if ('serviceWorker' in navigator && !isADevelopmentBuild) {
  const worker = new URL('service-worker.js', document.baseURI);
  const register = () => navigator.serviceWorker.register(worker);
  register().catch((error) => {
    console.warn('the app could not be kept for use without a network:', error);
  });

  // A browser checks for a new version only when a page of the app is opened,
  // and an app on a tablet on a music stand is opened once and left open. So
  // it is asked again every hour, whenever the app comes back into view, and
  // whenever the network does.
  //
  // A first version that could not be kept whole takes its registration with
  // it, and a registration that is gone has no update to ask for. So where
  // there is none any more, or asking fails, the worker is registered again,
  // and it picks up from what the attempt before it did fetch. A worker that
  // is still there is not fetched twice for it: registering the one that is
  // already registered is a no-op.
  const check = () =>
    navigator.serviceWorker
      .getRegistration()
      .then((registration) =>
        registration != null ? registration.update() : register())
      .catch(() => register())
      .catch(() => {});
  setInterval(check, 60 * 60 * 1000);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') check();
  });
  window.addEventListener('online', check);

  // A new version took over this page. What is on screen is the old version,
  // and what it has yet to load now comes from the new one, so the app offers
  // to start again on it (see lib/features/app_update). The first worker
  // taking over a page that had none is not a new version.
  let controlled = navigator.serviceWorker.controller != null;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (controlled) {
      window.scoreAppUpdated = true;
      window.dispatchEvent(new Event('score-app-updated'));
    }
    controlled = true;
  });
}

// Asked for, so that a browser short of space does not throw away the scores
// and the edits kept for a gig along with everything else it is holding. A
// browser that decides for itself answers in its own time; one that asks the
// player (Firefox) does so with a prompt, which is asked on the first tap or
// key rather than over a page that has not even drawn yet.
if (navigator.storage && navigator.storage.persist) {
  const askToKeep = () => {
    removeEventListener('pointerdown', askToKeep, true);
    removeEventListener('keydown', askToKeep, true);
    navigator.storage.persisted()
      .then((kept) => kept || navigator.storage.persist())
      .catch(() => {});
  };
  addEventListener('pointerdown', askToKeep, true);
  addEventListener('keydown', askToKeep, true);
}

_flutter.loader.load();

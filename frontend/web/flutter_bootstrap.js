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
  navigator.serviceWorker
    .register(new URL('service-worker.js', document.baseURI))
    .then((registration) => {
      // A browser checks for a new version only when a page of the app is
      // opened, and an app on a tablet on a music stand is opened once and left
      // open. So it is asked again every hour, and whenever the app comes back
      // into view.
      const check = () => registration.update().catch(() => {});
      setInterval(check, 60 * 60 * 1000);
      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'visible') check();
      });
    })
    .catch((error) => {
      console.warn('the app could not be kept for use without a network:', error);
    });

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

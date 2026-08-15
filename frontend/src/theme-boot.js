/*
 * Which way round this device reads, said before anything is drawn.
 *
 * This is a plain script rather than a module on purpose: a module is deferred,
 * and a page that starts light and corrects itself a moment later is a white
 * screen in somebody's face on a dark stage. It runs in the head, it touches
 * one attribute, and it is over before the first paint.
 *
 * The key is the one `domains/settings/settings.js` writes, and the two have to
 * agree. Nothing else is duplicated: how the page a score is drawn on is lit is
 * arithmetic, and that stays in the module, applied by the pages that draw one.
 */
(function () {
    try {
        var mode = localStorage.getItem('score-theme-mode');
        if (mode === 'light' || mode === 'dark') {
            document.documentElement.setAttribute('data-theme', mode);
        }
    } catch (error) {
        // A browser that will not open its storage is a browser that follows
        // the machine, which is what the app does when it has been told
        // nothing anyway.
        console.error('failed to read which way round this device reads', error);
    }
})();

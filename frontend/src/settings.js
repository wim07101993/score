import {Settings} from "./domains/settings/settings.js";
import {installedVersions, keepAppUpToDate, reinstallApp} from "./domains/updates/app-update.js";
import {DIMMEST, FULL} from "./domains/settings/sheet-palette.js";

/**
 * What this device prefers, and the one page that can be reached when the rest
 * of the app cannot start.
 *
 * Nothing here needs the config, the provider or the database: a reader whose
 * app is showing them nothing should still be able to turn the lamp up and
 * fetch the app again. So this page is written against the settings and the
 * worker alone.
 *
 * Every control writes the moment it is touched. There is no save button here,
 * as there is none anywhere else in this app.
 */

const themeModeInputs = document.querySelectorAll('input[name="theme-mode"]');

const pageHeading = document.getElementById('page-heading');
const resetLookButton = document.getElementById('reset-look-button');
const brightnessInput = document.getElementById('brightness-input');
const brightnessOutput = document.getElementById('brightness-output');
const warmthInput = document.getElementById('warmth-input');
const warmthOutput = document.getElementById('warmth-output');
const otherPageNote = document.getElementById('other-page-note');

const appState = document.getElementById('app-state');
const updateAppButton = document.getElementById('update-app-button');
const updateState = document.getElementById('update-state');

// ----------------------------------------------------------------------------
// LIGHT AND DARK
// ----------------------------------------------------------------------------

function _drawThemeMode() {
  const mode = Settings.themeMode;
  for (const input of themeModeInputs) {
    input.checked = input.value === mode;
  }
}

/**
 * @param event {Event}
 */
function onThemeModeChanged(event) {
  Settings.themeMode = event.target.value;
  Settings.apply();
  // The lamp is kept apart for the two rooms, so changing which room this is
  // changes what the dials are holding.
  _drawPageLook();
}

// ----------------------------------------------------------------------------
// THE PAGE, AND THE LAMP ON IT
// ----------------------------------------------------------------------------

function _drawPageLook() {
  const brightness = Settings.brightness;
  const look = Settings.pageLook(brightness);

  pageHeading.innerText = brightness === 'dark'
    ? 'The page, in the dark'
    : 'The page, in the light';
  otherPageNote.innerText = brightness === 'dark'
    ? 'The light page is set separately — switch to Light above to set it.'
    : 'The dark page is set separately — switch to Dark above to set it.';

  brightnessInput.value = `${look.brightness}`;
  warmthInput.value = `${look.warmth}`;
  _drawReadouts(look);

  resetLookButton.disabled = Settings.isPageLookDefault(brightness);
}

/**
 * @param look {import("./domains/settings/sheet-palette.js").PageLook}
 */
function _drawReadouts(look) {
  brightnessOutput.innerText = `${Math.round(look.brightness * 100)}%`;
  // Nothing is worth saying as a word rather than as a number: a page that has
  // had no warmth put into it is not a page turned 0% of the way towards
  // candlelight, it is a page nobody has warmed.
  warmthOutput.innerText = look.warmth < 0.005
    ? 'none'
    : `${Math.round(look.warmth * 100)}%`;
}

/**
 * A slider is dragged rather than tapped, so this runs on every step of the
 * drag: what is on screen has to keep up with the thumb, and the writing is a
 * short string in this browser's own storage.
 */
function onLookChanged() {
  const look = {
    brightness: Number(brightnessInput.value),
    warmth: Number(warmthInput.value),
  };
  Settings.setPageLook(Settings.brightness, look);
  Settings.apply();
  _drawReadouts(look);
  resetLookButton.disabled = Settings.isPageLookDefault(Settings.brightness);
}

function onResetLookClicked() {
  Settings.resetPageLook(Settings.brightness);
  Settings.apply();
  _drawPageLook();
}

// ----------------------------------------------------------------------------
// THE APP ITSELF
// ----------------------------------------------------------------------------

async function _drawAppState() {
  const versions = await installedVersions();

  appState.replaceChildren();
  for (const row of [
    {
      term: 'Version',
      // More than one means a newer version has been fetched and is waiting to
      // take over, which is worth being able to see.
      value: versions.join(', '),
      absent: 'nothing cached on this device yet',
    },
    {
      term: 'Served from this device',
      value: navigator.serviceWorker?.controller == null ? 'no' : 'yes',
    },
    {
      term: 'This device is',
      value: navigator.onLine === false ? 'offline' : 'online',
    },
  ]) {
    const term = document.createElement('dt');
    term.innerText = row.term;

    const value = document.createElement('dd');
    if (row.value == null || row.value === '') {
      value.innerText = row.absent ?? 'not known';
      value.className = 'muted';
    } else {
      value.innerText = row.value;
    }

    appState.append(term, value);
  }
}

async function onUpdateAppClicked() {
  updateAppButton.disabled = true;
  updateState.innerText = 'Throwing away what is cached and fetching the app again…';
  await reinstallApp();
}

// ----------------------------------------------------------------------------

async function main() {
  // Written before anything is read: every one of these is a control to reach
  // for when the app is not behaving, and none of them should depend on the
  // rest of the page having worked.
  for (const input of themeModeInputs) {
    input.addEventListener('change', onThemeModeChanged);
  }
  brightnessInput.addEventListener('input', onLookChanged);
  warmthInput.addEventListener('input', onLookChanged);
  resetLookButton.addEventListener('click', onResetLookClicked);
  updateAppButton.addEventListener('click', onUpdateAppClicked);

  // The ends of the dials are the palette's to decide, not the markup's.
  brightnessInput.min = `${DIMMEST}`;
  brightnessInput.max = `${FULL}`;

  Settings.apply();
  _drawThemeMode();
  _drawPageLook();

  // While the reader is following the machine, the machine changing its mind
  // changes which page these dials are setting.
  Settings.whenTheMachineChangesItsMind(() => {
    if (Settings.themeMode === 'system') {
      Settings.apply();
      _drawPageLook();
    }
  });

  await _drawAppState();

  // This page is safe to have pulled out from under the reader: everything it
  // holds is already written, and the state it shows is worth being the newest
  // version of.
  await keepAppUpToDate({reloadWhenReplaced: true});
  await _drawAppState();
}

await main();

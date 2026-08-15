import {
  clampBrightness,
  clampWarmth,
  defaultPageLook,
  sameLook,
  SheetPalette,
} from './sheet-palette.js';

/**
 * What this device has been told to prefer.
 *
 * It belongs to the device rather than to the account: a player may read off a
 * bright laptop at home and a dimmed tablet on a stand, signed in as the same
 * person, and neither should decide the other. So it is kept in this browser
 * and never sent to the server.
 *
 * Anything unreadable — a key from a version that wrote them differently, half
 * of a pair of numbers, a storage the browser refuses to open — reads as a
 * device that has never been asked. Settings are not worth a page that will not
 * start.
 */

/** @type {string} */
export const themeModeStorageKey = 'score-theme-mode';

/**
 * The three answers. "system" is what an app has when it has been told nothing,
 * so it is stored as nothing: a device that has never been asked and one that
 * has been put back to following the system are the same device.
 *
 * @type {readonly string[]}
 */
export const THEME_MODES = ['system', 'light', 'dark'];

/**
 * Which of the two rooms the app is in — not what the reader chose, but what is
 * on the screen because of it.
 *
 * @typedef {'light'|'dark'} Brightness
 */

/**
 * @param brightness {Brightness}
 * @return {string}
 */
function pageLookStorageKey(brightness) {
  return `score-page-look-${brightness}`;
}

export class Settings {

  /**
   * Light, dark, or whatever the machine says.
   *
   * @return {'system'|'light'|'dark'}
   */
  static get themeMode() {
    const stored = _read(themeModeStorageKey);
    return THEME_MODES.includes(stored) ? stored : 'system';
  }

  /**
   * @param mode {'system'|'light'|'dark'}
   */
  static set themeMode(mode) {
    _write(themeModeStorageKey, mode === 'system' || !THEME_MODES.includes(mode) ? null : mode);
  }

  /**
   * How the page is lit when the app is `brightness`.
   *
   * Kept apart for the two, because they are two different rooms: the lamp a
   * reader wants at a lit desk is not the one they want at a gig, and being
   * asked to set it again every time the sun goes down would be worse than not
   * being asked at all.
   *
   * @param brightness {Brightness}
   * @return {import('./sheet-palette.js').PageLook}
   */
  static pageLook(brightness) {
    const fallback = defaultPageLook(brightness);
    const parts = (_read(pageLookStorageKey(brightness)) ?? '').split(',');
    if (parts.length !== 2) {
      return fallback;
    }
    const lamp = Number(parts[0]);
    const warmth = Number(parts[1]);
    if (!Number.isFinite(lamp) || !Number.isFinite(warmth)) {
      return fallback;
    }
    return {brightness: clampBrightness(lamp), warmth: clampWarmth(warmth)};
  }

  /**
   * @param brightness {Brightness}
   * @param look {import('./sheet-palette.js').PageLook}
   */
  static setPageLook(brightness, look) {
    const held = {
      brightness: clampBrightness(look?.brightness),
      warmth: clampWarmth(look?.warmth),
    };
    _write(
      pageLookStorageKey(brightness),
      sameLook(held, defaultPageLook(brightness))
        ? null
        : `${held.brightness},${held.warmth}`,
    );
  }

  /**
   * Puts the page back to what it was before anybody touched it.
   *
   * @param brightness {Brightness}
   */
  static resetPageLook(brightness) {
    Settings.setPageLook(brightness, defaultPageLook(brightness));
  }

  /**
   * @param brightness {Brightness}
   * @return {boolean}
   */
  static isPageLookDefault(brightness) {
    return sameLook(Settings.pageLook(brightness), defaultPageLook(brightness));
  }

  /**
   * Which way round the app is right now: what the reader chose, or what the
   * machine says when they chose nothing.
   *
   * @return {Brightness}
   */
  static get brightness() {
    const mode = Settings.themeMode;
    if (mode !== 'system') {
      return mode;
    }
    return _prefersDark()?.matches === true ? 'dark' : 'light';
  }

  /**
   * The page as it is lit right now, ready to be handed to a stylesheet or to
   * whatever is drawing the music.
   *
   * @return {SheetPalette}
   */
  static get sheetPalette() {
    const look = Settings.pageLook(Settings.brightness);
    return SheetPalette.lamp(look.brightness, look.warmth);
  }

  /**
   * Puts what this device prefers on the document: which way round it is, and
   * how the page it draws music on is lit.
   *
   * `theme-boot.js` has already said which way round the app is, before
   * anything was drawn — this says it again, which costs nothing, and is what
   * makes the settings page able to show a choice the moment it is made.
   *
   * @param root {HTMLElement} the element the tokens live on, which is the
   *   document itself unless something is being previewed on its own
   */
  static apply(root = document.documentElement) {
    const mode = Settings.themeMode;
    if (mode === 'system') {
      root.removeAttribute('data-theme');
    } else {
      root.setAttribute('data-theme', mode);
    }
    Settings.applySheetPalette(Settings.sheetPalette, root);
  }

  /**
   * @param palette {SheetPalette}
   * @param root {HTMLElement}
   */
  static applySheetPalette(palette, root = document.documentElement) {
    root.style.setProperty('--paper', palette.paper);
    root.style.setProperty('--ink', palette.ink);
    root.style.setProperty('--ink-faded', palette.fadedInk);
  }

  /**
   * Calls back whenever the machine changes its mind about light and dark,
   * which matters while the reader is following it.
   *
   * @param listener {function(): void}
   */
  static whenTheMachineChangesItsMind(listener) {
    _prefersDark()?.addEventListener('change', listener);
  }
}

/**
 * @return {MediaQueryList|null}
 */
function _prefersDark() {
  if (typeof globalThis.matchMedia !== 'function') {
    return null;
  }
  return globalThis.matchMedia('(prefers-color-scheme: dark)');
}

/**
 * @param key {string}
 * @return {string|null}
 */
function _read(key) {
  try {
    return localStorage.getItem(key);
  } catch (error) {
    console.error('failed to read a setting', error);
    return null;
  }
}

/**
 * @param key {string}
 * @param value {string|null} nothing is stored as nothing rather than as the
 *   word "null", which the next reader would take for a setting
 */
function _write(key, value) {
  try {
    if (value == null) {
      localStorage.removeItem(key);
    } else {
      localStorage.setItem(key, value);
    }
  } catch (error) {
    console.error('failed to remember a setting', error);
  }
}

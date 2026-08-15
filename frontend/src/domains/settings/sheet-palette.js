/**
 * Paper, and the ink on it.
 *
 * The two are chosen together and never apart. Paper that followed the theme
 * while the ink did not — or the other way round — is pale grey notes on a
 * white page, which is the one way this can go wrong.
 *
 * Nothing here touches the document: it is arithmetic, and what is done with
 * the answer is `settings.js`'s business.
 */

/**
 * The dimmest the page is allowed to go.
 *
 * Below this the ink cannot stay clear of the page: black on a page this dim is
 * already down at about four to one, and a staff line is a hairline.
 *
 * @type {number}
 */
export const DIMMEST = 0.18;

/** Paper under a working light. @type {number} */
export const FULL = 1.0;

/**
 * Where the lamp starts when the app is dark and the reader has not said
 * otherwise, with a little warmth in it, which most people want at night and
 * nobody misses in the dark.
 *
 * @type {number}
 */
export const NIGHT = 0.29;

/** @type {number} */
export const NIGHT_WARMTH = 0.3;

/**
 * How the page is lit: what it gives off, and how far from grey it is.
 *
 * Both are shares between nothing and everything, and both belong to a reader
 * and a room rather than to an app.
 *
 * @typedef {{brightness: number, warmth: number}} PageLook
 */

/**
 * Where the lamp starts before anybody has touched it: a white page in a lit
 * room, and a dimmed, slightly warm one in a dark one.
 *
 * @param brightness {'light'|'dark'} which of the two rooms this is
 * @return {PageLook}
 */
export function defaultPageLook(brightness) {
  return brightness === 'dark'
    ? {brightness: NIGHT, warmth: NIGHT_WARMTH}
    : {brightness: FULL, warmth: 0};
}

/**
 * @param value {*} anything that is not a share of light at all reads as a page
 *   at full, which is the page nobody has touched
 * @return {number}
 */
export function clampBrightness(value) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return FULL;
  }
  return Math.min(FULL, Math.max(DIMMEST, value));
}

/**
 * @param value {*}
 * @return {number}
 */
export function clampWarmth(value) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return 0;
  }
  return Math.min(1, Math.max(0, value));
}

/**
 * @param a {PageLook}
 * @param b {PageLook}
 * @return {boolean}
 */
export function sameLook(a, b) {
  return a.brightness === b.brightness && a.warmth === b.warmth;
}

export class SheetPalette {
  /**
   * @param paper {string} the page, as a colour a stylesheet can be handed
   * @param ink {string} everything drawn on it: staff lines, noteheads, stems,
   *   words
   * @param fadedInk {string} a grace note, which leans on the note after it and
   *   is drawn lighter to say so
   */
  constructor(paper, ink, fadedInk) {
    this.paper = paper;
    this.ink = ink;
    this.fadedInk = fadedInk;
  }

  /**
   * A page with a lamp on it.
   *
   * `brightness` is what the page gives off, as a share of a white one: 1 is
   * paper under a working light, and the numbers below that are the same page
   * with the lamp turned down. It is the reader's to set, and it is the whole of
   * what "dark" means for a score — a score in the dark is still ink on paper,
   * and every version of this that swapped them round, light marks on a dark
   * page, was wrong in the same way. A screen makes its own light and pushes it
   * at the reader; in a dark room the eye opens up and anything bright on that
   * screen blooms, which is exactly what a white notehead is. Dark marks cannot
   * bloom. They have no light to give.
   *
   * It is a share of *light*, not of the numbers a colour is written with. Half
   * way down this scale is a page that throws half the light, which is what an
   * eye reckons by; the sRGB grey that does that is `#bcbcbc`, nowhere near the
   * halfway `#808080`. So the scale is worked in luminance and turned back into
   * a colour at the end, and a reader dragging it feels an even dimming rather
   * than a lot of nothing at one end and a cliff at the other.
   *
   * `warmth` is how far from grey the page is, from 0 for neutral to 1 for
   * something like paper by candlelight. It costs almost no light — it is the
   * blue that is taken away — so it can be had at any brightness. Ink takes a
   * little of it too: a black that stays blue-black on a warm page reads as a
   * hole in it.
   *
   * @param brightness {number}
   * @param warmth {number}
   * @return {SheetPalette}
   */
  static lamp(brightness, warmth = 0) {
    const lamp = clampBrightness(brightness);
    const warm = clampWarmth(warmth);
    const grey = greyGiving(lamp);

    // Held at a near-black rather than black, and let all the way down to black
    // only as the page comes up to full: ink darker than the darkest thing a
    // dimmed screen can show is ink nobody gains anything from.
    const ink = [
      (17 + 9 * warm) * (1 - lamp),
      (19 + 3 * warm) * (1 - lamp),
      (22 - 11 * warm) * (1 - lamp),
    ];

    return new SheetPalette(
      // Balanced so that warming the page does not also brighten it: red is
      // worth about three times as much light as blue, so nine points of red
      // buys back the twenty-six taken out of blue. Two dials that moved each
      // other would be two dials nobody could set.
      _hex(grey + 9 * warm, grey, grey - 26 * warm),
      _hex(...ink),
      // A dimmer page has less room between its darkest and its lightest, so a
      // grace note gives up less of what there is.
      _rgba(...ink, 0.62 - 0.07 * lamp),
    );
  }
}

/**
 * The sRGB grey that gives off `luminance` of what white gives off, as a number
 * between 0 and 255.
 *
 * @param luminance {number}
 * @return {number}
 */
export function greyGiving(luminance) {
  const value = luminance <= 0.0031308
    ? luminance * 12.92
    : 1.055 * Math.pow(luminance, 1 / 2.4) - 0.055;
  return Math.min(255, Math.max(0, value * 255));
}

/**
 * @param red {number}
 * @param green {number}
 * @param blue {number}
 * @return {string}
 */
function _hex(red, green, blue) {
  return `#${_channel(red)}${_channel(green)}${_channel(blue)}`;
}

/**
 * @param red {number}
 * @param green {number}
 * @param blue {number}
 * @param alpha {number}
 * @return {string}
 */
function _rgba(red, green, blue, alpha) {
  const opacity = Math.min(1, Math.max(0, alpha));
  return `rgb(${_byte(red)} ${_byte(green)} ${_byte(blue)} / ${opacity.toFixed(2)})`;
}

/**
 * @param value {number}
 * @return {number}
 */
function _byte(value) {
  return Math.min(255, Math.max(0, Math.round(value)));
}

/**
 * @param value {number}
 * @return {string}
 */
function _channel(value) {
  return _byte(value).toString(16).padStart(2, '0');
}

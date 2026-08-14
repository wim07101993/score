/**
 * How big the music is drawn, and the pinch that changes it.
 *
 * This is deliberately not part of a {@link import('./score-view.js').ScoreView}.
 * Hiding a part or transposing says something about the music; how big it is
 * drawn says something about the player's eyes and the tablet on the stand.
 * Nothing here is ever written into a set or handed back to the API, and a
 * score that has been blown up is still the score as it was written.
 *
 * A pinch is a ratio rather than a distance. What fingers do is come apart or
 * together, and how far apart they were when they landed is the only thing that
 * says what that means. So a pinch remembers where it started — both the zoom
 * and the distance — and every reading is taken against that, which is also
 * what keeps a slow pinch from drifting the way one that measured each step
 * against the last one would.
 */

/**
 * Half size is as small as music can be got before it stops being readable at
 * all; four times is a bar or two on a screen, which is as far as anybody needs
 * to go to read a score with their glasses off.
 */
export const MIN_ZOOM = 0.5;
export const MAX_ZOOM = 4;
export const DEFAULT_ZOOM = 1;

/**
 * @param zoom {number} anything that is not a size at all reads as the size a
 *   score is written at, and anything past the ends stops there
 * @return {number}
 */
export function clampZoom(zoom) {
  if (typeof zoom !== 'number' || !Number.isFinite(zoom)) {
    return DEFAULT_ZOOM;
  }
  return Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, zoom));
}

/**
 * @param a {{x: number, y: number}}
 * @param b {{x: number, y: number}}
 * @return {number}
 */
export function distanceBetween(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

export class Pinch {
  /**
   * Prefer {@link Pinch.begin}; this takes its arguments already validated.
   *
   * @param zoom {number} how big the music was when the fingers landed
   * @param distance {number} how far apart they landed
   */
  constructor(zoom, distance) {
    this._zoom = zoom;
    this._distance = distance;
    Object.freeze(this);
  }

  /**
   * @param zoom {number}
   * @param distance {number}
   * @return {Pinch|null} null when the two fingers are in the same place, which
   *   is no distance to measure anything against
   */
  static begin(zoom, distance) {
    if (!Number.isFinite(distance) || distance <= 0) {
      return null;
    }
    return new Pinch(clampZoom(zoom), distance);
  }

  /** @return {number} how big the music was when the pinch started */
  get zoom() {
    return this._zoom;
  }

  /**
   * How big the music is with the fingers this far apart.
   *
   * @param distance {number}
   * @return {number}
   */
  zoomAt(distance) {
    if (!Number.isFinite(distance) || distance <= 0) {
      return this._zoom;
    }
    return clampZoom(this._zoom * (distance / this._distance));
  }

  /**
   * What the music on screen should be multiplied by to show a pinch that is
   * still going on.
   *
   * This is taken from {@link zoomAt} rather than from the fingers directly, so
   * that a pinch that has run into the end of the range stops growing on screen
   * as well: what is shown while pinching is always what letting go will draw.
   *
   * @param distance {number}
   * @return {number}
   */
  scaleAt(distance) {
    return this.zoomAt(distance) / this._zoom;
  }
}
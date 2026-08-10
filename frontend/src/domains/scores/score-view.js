/**
 * How a score is being looked at: which of its parts are on screen and by how
 * much it is transposed.
 *
 * A view is never stored and never travels back to the API. The document a
 * score is made of is what the editor uploaded and stays that way; hiding a
 * part or transposing is something that happens on the way to the screen and
 * nowhere else.
 *
 * The state is immutable for the same reason: every change hands back a new
 * view, so the one a caller is holding can never turn into something else
 * underneath it, and putting a view back the way it was is a matter of keeping
 * the old one around.
 */

/** The furthest a score can be transposed in either direction, in semitones. */
export const MIN_TRANSPOSITION = -12;
export const MAX_TRANSPOSITION = 12;

export class ScoreView {
  /**
   * Prefer {@link ScoreView.forParts}; this takes its arguments already
   * validated.
   *
   * @param partIds {string[]} every part of the score, in the order the score
   *   lists them
   * @param hiddenPartIds {string[]} the parts that are not on screen
   * @param transposition {number} semitones
   */
  constructor(partIds, hiddenPartIds, transposition) {
    this._partIds = Object.freeze([...partIds]);
    this._hiddenPartIds = Object.freeze([...hiddenPartIds]);
    this._transposition = transposition;
    Object.freeze(this);
  }

  /**
   * The view a score opens in: every part on screen, written as it was
   * written.
   *
   * @param partIds {string[]}
   * @return {ScoreView}
   */
  static forParts(partIds) {
    return new ScoreView(partIds, [], 0);
  }

  /** @return {string[]} */
  get partIds() {
    return this._partIds;
  }

  /** @return {string[]} */
  get hiddenPartIds() {
    return this._hiddenPartIds;
  }

  /** @return {number} semitones, negative for down */
  get transposition() {
    return this._transposition;
  }

  /** @return {string[]} the parts on screen, in the order the score lists them */
  get visiblePartIds() {
    return this._partIds.filter((id) => !this._hiddenPartIds.includes(id));
  }

  /**
   * @param partId {string}
   * @return {boolean}
   */
  isHidden(partId) {
    return this._hiddenPartIds.includes(partId);
  }

  /** @return {boolean} whether this is the score as it was written */
  get isPristine() {
    return this._transposition === 0 && this._hiddenPartIds.length === 0;
  }

  /**
   * @param semitones {number} anything beyond an octave either way is brought
   *   back to it, and a fraction of a semitone is not a transposition anyone
   *   can read, so it is rounded
   * @return {ScoreView}
   */
  withTransposition(semitones) {
    if (typeof semitones !== 'number' || !Number.isFinite(semitones)) {
      return this;
    }

    const clamped = Math.min(MAX_TRANSPOSITION, Math.max(MIN_TRANSPOSITION, Math.round(semitones)));
    if (clamped === this._transposition) {
      return this;
    }
    return new ScoreView(this._partIds, this._hiddenPartIds, clamped);
  }

  /**
   * Takes a part off the screen or puts it back.
   *
   * Hiding the last part that is left is refused rather than obeyed: a score
   * with nothing on it is not a view of anything, and there would be no part
   * left to click to get back. The view is returned unchanged, so a caller that
   * draws its controls from the view shows the part as still visible.
   *
   * @param partId {string}
   * @param visible {boolean}
   * @return {ScoreView}
   */
  withPartVisible(partId, visible) {
    if (!this._partIds.includes(partId)) {
      return this;
    }
    if (visible === !this.isHidden(partId)) {
      return this;
    }

    if (visible) {
      return new ScoreView(
        this._partIds,
        this._hiddenPartIds.filter((id) => id !== partId),
        this._transposition);
    }

    if (this.visiblePartIds.length <= 1) {
      return this;
    }
    return new ScoreView(
      this._partIds,
      [...this._hiddenPartIds, partId],
      this._transposition);
  }

  /**
   * The same score with exactly these parts off the screen, whatever was off it
   * before.
   *
   * This is how a score is opened the way a set says it is played: a set names
   * the parts that are off screen all at once, and putting them off one by one
   * would depend on the order they happen to be in.
   *
   * Parts the score does not have are ignored rather than refused: a set is
   * written against the score as it was then, and a score that has been
   * uploaded again since may no longer have the part that was hidden. Hiding
   * every part there is, is refused the same way hiding the last one is.
   *
   * @param partIds {string[]}
   * @return {ScoreView}
   */
  withHiddenParts(partIds) {
    if (!Array.isArray(partIds)) {
      return this;
    }

    const hidden = this._partIds.filter((id) => partIds.includes(id));
    if (hidden.length >= this._partIds.length) {
      return this;
    }
    if (hidden.length === this._hiddenPartIds.length
      && hidden.every((id) => this._hiddenPartIds.includes(id))) {
      return this;
    }
    return new ScoreView(this._partIds, hidden, this._transposition);
  }

  /**
   * The same score, looked at the way it was written.
   *
   * @return {ScoreView}
   */
  reset() {
    return ScoreView.forParts(this._partIds);
  }
}

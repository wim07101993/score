import {ScoreView} from './score-view.js';

/**
 * Draws a score with OpenSheetMusicDisplay the way a {@link ScoreView}
 * describes it.
 *
 * The renderer holds on to the music-xml it was given and every drawing is
 * derived from it. Nothing here ever writes to that document, so the score that
 * is downloaded or re-uploaded is always the one the editor uploaded, whatever
 * is currently on screen.
 */

/**
 * @typedef {Object} ScorePart
 * @property {string} id
 * @property {string} name what to call the part in a control
 */

export class ScoreRenderer {
  /**
   * @param osmd {Object} an OpenSheetMusicDisplay bound to a container
   */
  constructor(osmd) {
    this._osmd = osmd;
    /** The score as it was uploaded. Read, never written. @type {string|null} */
    this._musicXml = null;
    /** @type {ScorePart[]} */
    this._parts = [];
    /**
     * The transposition the sheet in memory has been put through, which is not
     * the same thing as the one the view asks for; see {@link apply}.
     * @type {number}
     */
    this._appliedTransposition = 0;
  }

  /** @return {ScorePart[]} */
  get parts() {
    return this._parts;
  }

  /**
   * Reads a score and draws it as it was written.
   *
   * @param musicXml {string}
   * @return {Promise<ScoreView>} the view it is being shown in
   */
  async load(musicXml) {
    this._musicXml = musicXml;
    await this._osmd.load(musicXml);
    this._appliedTransposition = 0;
    this._parts = readParts(this._osmd);

    const view = ScoreView.forParts(this._parts.map((part) => part.id));
    this._draw(view);
    return view;
  }

  /**
   * Draws the score the way the view describes it.
   *
   * Transposing is not something OSMD can take back: it rewrites the keys of
   * the sheet it holds in memory, and asking for a transposition of zero again
   * does not put them back the way they were. So a change of transposition
   * starts over from the document, which is exactly what makes it undoable.
   * Hiding a part is only a flag on the sheet, so that needs no such thing.
   *
   * @param view {ScoreView}
   * @return {Promise<void>}
   */
  async apply(view) {
    if (this._musicXml == null) {
      return;
    }

    if (view.transposition !== this._appliedTransposition) {
      await this._osmd.load(this._musicXml);
      this._appliedTransposition = 0;
    }
    this._draw(view);
  }

  /**
   * @param view {ScoreView}
   * @private
   */
  _draw(view) {
    const sheet = this._osmd.Sheet;
    if (sheet == null) {
      return;
    }

    this._parts.forEach((part, index) => {
      const instrument = sheet.Instruments[index];
      if (instrument != null) {
        instrument.Visible = !view.isHidden(part.id);
      }
    });

    if (view.transposition !== 0) {
      // OSMD needs something to transpose with before it will transpose, and it
      // keeps the calculator on a static, so this is worth doing only once.
      ensureTransposeCalculator(this._osmd);
    }
    sheet.Transpose = view.transposition;
    this._appliedTransposition = view.transposition;

    // The drawing is built from the parsed sheet, so it has to be rebuilt
    // before rendering or none of the above is on screen.
    this._osmd.updateGraphic();
    this._osmd.render();
  }
}

/**
 * Reads the parts of the sheet OSMD currently has loaded.
 *
 * MusicXML part ids are unique in a valid document, but a document that is
 * being read is not always valid, so a part without a usable id falls back to
 * its position.
 *
 * @param osmd {Object} a loaded OpenSheetMusicDisplay
 * @return {ScorePart[]} empty when no score is loaded
 */
export function readParts(osmd) {
  const instruments = osmd?.Sheet?.Instruments;
  if (instruments == null) {
    return [];
  }

  const parts = [];
  const taken = new Set();
  instruments.forEach((instrument, index) => {
    let id = `${instrument.IdString ?? ''}`;
    if (id === '' || taken.has(id)) {
      id = `part-${index}`;
    }
    taken.add(id);

    const name = `${instrument.Name ?? ''}`.trim();
    parts.push({id: id, name: name === '' ? `Part ${index + 1}` : name});
  });
  return parts;
}

/**
 * @param osmd {Object}
 */
function ensureTransposeCalculator(osmd) {
  if (osmd.TransposeCalculator != null) {
    return;
  }
  osmd.TransposeCalculator = new opensheetmusicdisplay.TransposeCalculator();
}

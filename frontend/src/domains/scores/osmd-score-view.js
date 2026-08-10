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

const SVG_NAMESPACE = 'http://www.w3.org/2000/svg';

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
   * What is on the screen, as a picture of it.
   *
   * This is the one way out of here that is the view and not the score: a
   * drawing of the parts that are showing, in the key they are being read in,
   * laid out exactly as they are being read. It is what to print and what to
   * hand to somebody who only wants to play it, and it is not a score any more
   * — nothing can be transposed out of it again.
   *
   * A score of several pages is stacked into one picture rather than handed
   * back a page at a time, since what was asked for was the score.
   *
   * @return {string|null} null when there is nothing drawn to take a copy of
   */
  toSvg() {
    const pages = this._pages();
    if (pages.length === 0) {
      return null;
    }

    const svg = document.implementation.createDocument(SVG_NAMESPACE, 'svg', null);
    const sheet = svg.documentElement;

    let width = 0;
    let height = 0;
    for (const page of pages) {
      const size = _sizeOf(page);
      const copy = svg.importNode(page, true);
      // A page keeps its own coordinates and is placed as a whole, which is
      // what nesting one drawing inside another is for.
      copy.setAttribute('x', '0');
      copy.setAttribute('y', `${height}`);
      copy.setAttribute('width', `${size.width}`);
      copy.setAttribute('height', `${size.height}`);
      sheet.appendChild(copy);

      width = Math.max(width, size.width);
      height += size.height;
    }

    sheet.setAttribute('xmlns', SVG_NAMESPACE);
    sheet.setAttribute('width', `${width}`);
    sheet.setAttribute('height', `${height}`);
    sheet.setAttribute('viewBox', `0 0 ${width} ${height}`);

    // On the page the score is drawn on whatever the app is drawn on, and the
    // font it is set in comes from the app's own stylesheet. A file has neither
    // of those behind it, so both have to be said here or the score arrives
    // transparent and in somebody else's font.
    const style = svg.createElementNS(SVG_NAMESPACE, 'style');
    style.textContent = 'text { font-family: serif; }';
    const paper = svg.createElementNS(SVG_NAMESPACE, 'rect');
    paper.setAttribute('width', '100%');
    paper.setAttribute('height', '100%');
    paper.setAttribute('fill', '#ffffff');
    sheet.prepend(style, paper);

    return new XMLSerializer().serializeToString(svg);
  }

  /**
   * The drawing of each page, in the order they are read.
   *
   * @return {SVGSVGElement[]} empty unless the score is being drawn as svg
   * @private
   */
  _pages() {
    const pages = [];
    for (const backend of this._osmd?.Drawer?.Backends ?? []) {
      const page = backend.getSvgElement?.();
      if (page != null) {
        pages.push(page);
      }
    }
    return pages;
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
 * How big a drawn page is. The size is on the drawing itself, but a drawing
 * that has been laid out and never sized is measured off the screen instead.
 *
 * @param page {SVGSVGElement}
 * @return {{width: number, height: number}}
 */
function _sizeOf(page) {
  const width = Number.parseFloat(page.getAttribute('width'));
  const height = Number.parseFloat(page.getAttribute('height'));
  return {
    width: Number.isFinite(width) ? width : page.clientWidth,
    height: Number.isFinite(height) ? height : page.clientHeight,
  };
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

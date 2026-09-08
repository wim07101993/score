import {LitElement, html, nothing} from "../packages/lit-core.3.3.3.min.js";
import {getScoreTitle} from "../data/helper-functions.js";
import {getInstrumentName, getLanguageName} from "../data/translations.js";

/**
 * One score in the list: what it is called, who wrote it, what it is for, and
 * what it is sung in.
 *
 * It draws into the light DOM rather than into a shadow root of its own. A
 * shadow root would keep the app's stylesheet out, and then the card would need
 * its own copy of the colours and the spacing to stay in step with everything
 * else — which is exactly how two things that should look alike stop looking
 * alike. The tokens are the app's; the row only says what it is made of.
 *
 * A row rather than a card. A library is read down a column of titles: a grid
 * of tiles puts four scores on a screen where a list puts a dozen, and the
 * thing anybody is actually doing here is looking for one piece by name.
 *
 * The whole row is one link. A row that only responds to a click is a row that
 * cannot be tabbed to, opened in a new tab, or reached at all without a mouse.
 * The one thing that is not the link is the button beside it, which is why the
 * link is a link inside the row rather than the row itself: a button inside an
 * anchor is not a button anybody can press.
 */
export class ScoreCard extends LitElement {
  static properties = {
    score: {type: Object},
    /** Whether this row offers a way into the sets and collections. */
    filable: {type: Boolean},
  };

  createRenderRoot() {
    return this;
  }

  render() {
    if (this.score == null) {
      return nothing;
    }

    const composers = (this.score.creators?.composers ?? [])
      .concat(this.score.creators?.lyricists ?? []);
    const instruments = (this.score.instruments ?? []).map((one) => getInstrumentName(one));
    // Named rather than left as the codes they are stored as. A row that ends
    // in "nl" is a row that has to be worked out; one that ends in "Dutch" is
    // read. Instrumental music has no language at all and says nothing here.
    const languages = (this.score.languages ?? [])
      .map((one) => getLanguageName(one))
      .filter((one) => one !== '');
    const tags = this.score.tags ?? [];
    // Everything that is not the title, said on one line. On a row there is no
    // room for a label per fact, and who wrote a piece, what it is sung in and
    // what it is written for read as one sentence anyway.
    //
    // The language comes before the instruments rather than after them, which
    // is not the order the score's own page lists them in. The line is one line
    // and runs out on a phone, and it runs out in the middle of the
    // instruments: a word at the end is a word nobody ever sees. It is also the
    // fact most likely to be the whole question — the same song in Dutch and in
    // English is two rows that are otherwise identical — while a list of
    // instruments cut short still says what kind of thing this is.
    const meta = [composers.join(', '), languages.join(', '), instruments.join(', ')]
      .filter((part) => part !== '');

    return html`
      <div class="score-row">
        <a class="score-row-link"
           href="/scores/detail.html?${new URLSearchParams({id: this.score.id}).toString()}">
          <span class="score-row-title">${getScoreTitle(this.score)}</span>
          ${meta.length === 0 ? nothing : html`
            <span class="score-row-meta">${meta.join(' · ')}</span>`}
          ${tags.length === 0 ? nothing : html`
            <span class="score-row-tags">
              ${tags.map((tag) => html`<span class="chip">${tag}</span>`)}
            </span>`}
        </a>

        ${this.filable !== true ? nothing : html`
          <button type="button" class="button button--quiet button--icon score-row-file"
                  aria-label=${`Put ${getScoreTitle(this.score)} into a set or a collection`}
                  title="Sets and collections"
                  @click=${this._onFileClicked}>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true"
                 focusable="false">
              <path d="M4 4h6l2 2h8v12H4V4zm2 4v8h12V8H6z"/>
              <path d="M11 9h2v6h-2z"/>
              <path d="M9 11h6v2H9z"/>
            </svg>
          </button>`}
      </div>`;
  }

  /**
   * Says which score was asked about and leaves the answering to the page. What
   * sets and collections there are, and what it costs to write to one, is the
   * page's business; a row only knows which piece the reader pointed at.
   *
   * @param event {Event}
   */
  _onFileClicked(event) {
    // The row around the button is a link, and a click that reaches it opens
    // the score instead of the sets it is in.
    event.preventDefault();
    event.stopPropagation();
    this.dispatchEvent(new CustomEvent('file-score', {
      detail: {score: this.score},
      bubbles: true,
      composed: true,
    }));
  }
}

customElements.define('score-card', ScoreCard);

/**
 * @param score {import("../domains/scores/database.js").Score}
 * @param options {{filable?: boolean}} whether the row offers a way into the
 *   sets and collections, which is only true where there is a page listening
 *   for it.
 * @return {HTMLElement}
 */
export function buildScoreCard(score, options = {}) {
  const card = document.createElement('score-card');
  // Straight in as an object. Nothing has to be flattened into attributes and
  // read back out again, which is what the list item used to do.
  card.score = score;
  card.filable = options.filable === true;
  return card;
}

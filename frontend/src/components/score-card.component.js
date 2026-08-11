import {LitElement, html, nothing} from "../packages/lit-core.3.3.3.min.js";
import {getScoreTitle} from "../data/helper-functions.js";
import {getInstrumentName} from "../data/translations.js";

/**
 * One score in the list: what it is called, who wrote it, and what it is for.
 *
 * It draws into the light DOM rather than into a shadow root of its own. A
 * shadow root would keep the app's stylesheet out, and then the card would need
 * its own copy of the colours and the spacing to stay in step with everything
 * else — which is exactly how two things that should look alike stop looking
 * alike. The tokens are the app's; the card only says what it is made of.
 *
 * The whole card is one link. A card that only responds to a click is a card
 * that cannot be tabbed to, opened in a new tab, or reached at all without a
 * mouse.
 */
export class ScoreCard extends LitElement {
  static properties = {
    score: {type: Object},
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
    const tags = this.score.tags ?? [];

    return html`
      <a class="score-card"
         href="/scores/detail.html?${new URLSearchParams({id: this.score.id}).toString()}">
        <h2 class="score-card-title">${getScoreTitle(this.score)}</h2>

        ${composers.length === 0 ? nothing : html`
          <p class="score-card-line">
            <img src="/assets/icons/artist.svg" alt="" class="score-card-icon" aria-hidden="true"/>
            <span>${composers.join(', ')}</span>
          </p>`}

        ${instruments.length === 0 ? nothing : html`
          <p class="score-card-line">
            <img src="/assets/icons/instrument.svg" alt="" class="score-card-icon" aria-hidden="true"/>
            <span>${instruments.join(', ')}</span>
          </p>`}

        ${tags.length === 0 ? nothing : html`
          <p class="score-card-tags">
            ${tags.map((tag) => html`<span class="chip">${tag}</span>`)}
          </p>`}
      </a>`;
  }
}

customElements.define('score-card', ScoreCard);

/**
 * @param score {import("../domains/scores/database.js").Score}
 * @return {HTMLElement}
 */
export function buildScoreCard(score) {
  const card = document.createElement('score-card');
  // Straight in as an object. Nothing has to be flattened into attributes and
  // read back out again, which is what the list item used to do.
  card.score = score;
  return card;
}

import {appState} from "../app-state.js";
import {getInstrumentName} from "../data/instrument-names.js";

export function registerScoreDetail() {
  class ScoreDetail extends HTMLElement {
    static scoreIdAttribute = 'score-id';

    static get observedAttributes() {
      return [ScoreDetail.scoreIdAttribute];
    }

    constructor() {
      super();

      this.shadow = this.attachShadow({mode: 'open'});
      this.shadow.innerHTML = `
      <div id="container">
      </div>
      `;
      this.update();
    }

    attributeChangedCallback() {
      this.update();
    }

    async update() {
      const container = this.shadow.getElementById('container');

      await appState.initialization;

      const scoreId = this.getAttribute(ScoreDetail.scoreIdAttribute);
      let score = await appState.database.getScore(scoreId);

      if (score == null) {
        score = await appState.api.getScore(scoreId)
        if (score == null) {
          container.innerText = 'Could not find the score you were searching for.'
          return;
        }
      }

      container.innerHTML = `
      <header>
        <h1>${score.work.title ?? score.movement.title}</h1>
      </header>
      <div>
        <p>Lyricists: ${score.creators.lyricists.join(', ')}</p>
        <p>Composers: ${score.creators.composers.join(', ')}</p>
        <p>Instruments: ${score.instruments.map(getInstrumentName).join(', ')}</p>
        <p>Langauges: ${score.languages.join(', ')}</p>
        <p>Tags: ${score.tags.join(', ')}</p>
        <p>Last changed at: ${score.last_changed_timestamp ?? 'never'}</p>
      </div>
      `;
    }
  }

  customElements.define('score-detail', ScoreDetail);
}

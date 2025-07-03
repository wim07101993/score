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

    update() {
      const container = this.shadow.getElementById('container');
      container.innerText = this.getAttribute(ScoreDetail.scoreIdAttribute);
    }
  }

  customElements.define('score-detail', ScoreDetail);
}

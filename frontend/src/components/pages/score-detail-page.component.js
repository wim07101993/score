export function registerScoreDetailPage() {
  class ScoreDetailPage extends HTMLElement {
    constructor() {
      super();

      const scoreId = location.hash.replace('#/scores/', '');

      const shadowRoot = this.attachShadow({mode: 'open'});
      shadowRoot.innerHTML = `
      <header>
        <h1>Score detail</h1>
        <score-detail score-id="${scoreId}"></score-detail>
      </header>
      `;
    }
  }

  customElements.define('score-detail-page', ScoreDetailPage)
}

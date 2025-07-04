export function registerScoreDetailPage() {
  class ScoreDetailPage extends HTMLElement {
    constructor() {
      super();

      const scoreId = location.hash.replace('#/scores/', '');

      const shadowRoot = this.attachShadow({mode: 'open'});
      shadowRoot.innerHTML = `
        <score-detail score-id="${scoreId}"></score-detail>
      `;
    }
  }

  customElements.define('score-detail-page', ScoreDetailPage)
}

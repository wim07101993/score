export function registerScoreListPage() {
  class ScoreListPage extends HTMLElement {
    constructor() {
      super();

      const shadowRoot = this.attachShadow({mode: 'open'});
      shadowRoot.innerHTML = `
      <header>
        <h1>Scores</h1>
      </header>
      <score-list></score-list>
      `;
    }
  }

  customElements.define('score-list-page', ScoreListPage);
}

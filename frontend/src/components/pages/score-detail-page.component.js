export function registerScoreDetailPage() {
  class ScoreDetailPage extends HTMLElement {
    constructor() {
      super();

      const title = document.createElement('h1');
      title.innerText = 'Score detail';

      const header = document.createElement('header');
      header.appendChild(title);

      const shadowRoot = this.attachShadow({mode: 'open'});
      shadowRoot.appendChild(header);
    }
  }

  customElements.define('score-detail-page', ScoreDetailPage)
}

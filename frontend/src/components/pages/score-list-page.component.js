import {template} from "./score-list-page.template.js";

export async function registerScoreListPage() {
  class ScoreListPage extends HTMLElement {
    constructor() {
      super();

      const shadowRoot = this.attachShadow({mode: 'open'});
      shadowRoot.innerHTML = template;
    }
  }

  customElements.define('score-list-page', ScoreListPage);
}

import {getAllScores} from "../../data/database/database.js";
import {buildScoreListItem} from "../score-list-item/score-list-item.js";

export async function registerScoreList() {
  const template = await fetch('components/score-list/score-list.html')
    .then(stream => stream.text());

  class ScoreList extends HTMLElement {
    constructor() {
      super();

      const shadowRoot = this.attachShadow({mode: 'open'});
      shadowRoot.innerHTML = template;
      getAllScores()
        .then(scores => {
          for (let i = 0; i < scores.length; i++) {
            const score = scores[i];
            const listItem = buildScoreListItem(score);
            this.shadowRoot.appendChild(listItem);
          }
        })
    }
  }

  customElements.define('score-list', ScoreList)
}

import {getAllScores} from "../../data/database/database.js";
import {buildScoreListItem} from "../score-list-item/score-list-item.component.js";

export function registerScoreList() {
  class ScoreList extends HTMLElement {
    constructor() {
      super();

      const shadowRoot = this.attachShadow({mode: 'open'});
      getAllScores()
        .then(scores => {
          for (let i = 0; i < scores.length; i++) {
            const score = scores[i];
            const listItem = buildScoreListItem(score);
            shadowRoot.appendChild(listItem);
          }
        })
    }
  }

  customElements.define('score-list', ScoreList)
}

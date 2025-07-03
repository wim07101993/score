import {getAllScores} from "../data/database/database.js";
import {buildScoreListItem} from "./score-list-item.component.js";
import {scoreFetcher} from "../data/score-fetcher/score_fetcher.js";

export function registerScoreList() {
  class ScoreList extends HTMLElement {
    constructor() {
      super();

      this.shadow = this.attachShadow({mode: 'open'});
      this.shadow.innerHTML = `
      <style>
        #container {
          display: grid;
          grid-auto-flow: row;
          grid-row-gap: 8px;
        }
      </style>
      <div id="container">
      </div>
      `;

      const list = this;
      scoreFetcher.listenForScoresUpdated(() => {
        list.buildScoreListItems();
      })
      this.buildScoreListItems();
    }

    buildScoreListItems() {
      const container = this.shadow.getElementById('container');
      getAllScores().then(scores => {
        for (const score of scores) {
          const listItem = buildScoreListItem(score);
          container.appendChild(listItem);
        }
      });
    }
  }

  customElements.define('score-list', ScoreList)
}

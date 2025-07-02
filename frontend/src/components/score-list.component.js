import {getAllScores} from "../data/database/database.js";
import {buildScoreListItem} from "./score-list-item.component.js";
import {scoreFetcher} from "../data/score-fetcher/score_fetcher.js";

export function registerScoreList() {
  class ScoreList extends HTMLElement {
    static containerId = 'container';

    constructor() {
      super();

      this.shadow = this.attachShadow({mode: 'open'});

      const container = document.createElement('div');
      container.id = ScoreList.containerId;

      this.shadow.appendChild(this.buildStyle());
      this.shadow.appendChild(container);

      const list = this;
      scoreFetcher.listenForScoresUpdated(() => {
        list.buildScoreListItems();
      })
      this.buildScoreListItems();
    }

    buildScoreListItems() {
      const container = this.shadow.getElementById(ScoreList.containerId);
      getAllScores().then(scores => {
        for (const score of scores) {
          const listItem = buildScoreListItem(score);
          container.appendChild(listItem);
        }
      });
    }

    buildStyle() {
      const style = document.createElement('style')
      style.textContent = `
        #container {
          display: grid;
          grid-auto-flow: row;
          grid-row-gap: 8px;
        }
        `;
      return style;
    }
  }

  customElements.define('score-list', ScoreList)
}

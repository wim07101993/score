import {getAllScores} from "../data/database/database.js";
import {buildScoreListItem} from "./score-list-item.component.js";

export function registerScoreList() {
  class ScoreList extends HTMLElement {
    static containerId = 'container';

    constructor() {
      super();

      this.shadow = this.attachShadow({mode: 'open'});

      const container = document.createElement('div');
      container.id = ScoreList.containerId;

      getAllScores().then(scores => {
        for (const score of scores) {
          const listItem = buildScoreListItem(score);
          container.appendChild(listItem);
        }
      });

      this.shadow.appendChild(this.buildStyle());
      this.shadow.appendChild(container);
    }

    function

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

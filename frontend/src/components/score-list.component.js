import {buildScoreListItem} from "./score-list-item.component.js";
import {appState} from "../app-state.js";

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
      appState.database.addScoreChangesListener(() => list._buildScoreListItems());
      this._buildScoreListItems();
    }

    async _buildScoreListItems() {
      const container = this.shadow.getElementById('container');
      await appState.initialization;
      for (const score of appState.database.scores) {
        const listItem = buildScoreListItem(score);
        container.appendChild(listItem);
      }
    }
  }

  customElements.define('score-list', ScoreList)
}

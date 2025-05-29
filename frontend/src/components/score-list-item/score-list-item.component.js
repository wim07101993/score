import {Score} from '../../data/database/models.js';
import {template} from "./score-list-item.template.js";

export async function registerScoreListItem() {
  class ScoreListItem extends HTMLElement {
    constructor() {
      super();

      const shadowRoot = this.attachShadow({mode: 'open'});
      shadowRoot.innerHTML = template;
    }
  }

  customElements.define('score-list-item', ScoreListItem);
}

/**
 *
 * @param score {Score}
 * @returns HTMLElement
 */
export function buildScoreListItem(score) {
  const element = document.createElement('div')
  element.innerHTML = `
    <score-list-item>
      <span slot="title">${score.work?.title ?? score.movement?.title}</span>
      <span slot="creators">${score.creators.join(', ')}</span>
      <span slot="instruments">${score.instruments.join(', ')}</span>
      <span slot="tags">${score.tags.join(', ')}</span>
    </score-list-item>
  `;

  element.onclick = () => {
    window.location.href = `http://localhost:3000#/detail?scoreId=${score.id}`;
  }
  return element;
}

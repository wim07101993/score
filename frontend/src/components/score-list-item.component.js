import {Score} from '../data/database/models.js';
import {getListProperty} from '../data/html-functions.js';
import {getInstrumentName} from "../data/instrument-names.js";

export function registerScoreListItem() {
  class ScoreListItem extends HTMLElement {
    static titleAttributeName = 'title';

    static get observedAttributes() {
      return [ScoreListItem.titleAttributeName];
    }

    constructor() {
      super();
      this.shadow = this.attachShadow({mode: 'open'});
      this.shadow.innerHTML = `
      <style>
        #container {
            padding: 16px;
            border-style: solid;
            border-color: var(--primary-color);
            border-width: 1px;
            border-radius: 10px;
            background-color: var(--background);
        }
        
        #container:hover {
            padding: 15px;
            border-width: 2px;
        }
        
        #title {
            margin-top: 8px;
            margin-bottom: 0;
        }
        
        #creators {
            margin-top: 4px;
            margin-bottom: 0;
        }
        
        #instruments {
            margin-top: 4px;
            margin-bottom: 0;
        }
        
        #tags {
            margin-top: 4px;
            margin-bottom: 0;
        }
        
        .icon {
            filter: invert(0.5);
            margin-bottom: -6px;
        }
      </style>
      <div id="container">
        <h2 id="title"></h2>
        <p id="creators" class="score-property">
          <img src="assets/icons/artist.svg" alt="Creators: " class="icon"/>
          <span id="creators-span"></span>
        </p>
        <p id="instruments" class="score-property">
          <img src="assets/icons/instrument.svg" alt="Instruments: " class="icon"/>
          <span id="instruments-span"></span>
        </p>
        <p id="tags" class="score-property"></p>
      </div>
      `;
    }

    connectedCallback() {
      const scoreListItem = this;
      const observer = new MutationObserver(function () {
        scoreListItem.updateProperties()
      });
      observer.observe(this, {childList: true, subtree: true});
      this.updateProperties();
    }

    attributeChangedCallback() {
      this.updateProperties();
    }

    updateProperties() {
      this.shadow.getElementById('title').innerText = this.getAttribute(ScoreListItem.titleAttributeName);
      const instruments = this.shadow.getElementById('instruments-span');
      if (instruments !== null) {
        instruments.innerText = getListProperty(this, 'instruments', 'instrument')
          .map((instrument) => getInstrumentName(instrument))
          .join(', ');
      }
      const creators = this.shadow.getElementById('creators-span');
      if (creators !== null) {
        creators.innerHTML = getListProperty(this, 'creators', 'creator').join(', ');
      }
      const tags = this.shadow.getElementById('tags');
      if (tags !== null) {
        tags.innerText = getListProperty(this, 'tags', 'tag').join(', ');
      }
    }
  }

  customElements.define('score-list-item', ScoreListItem);
}

/**
 * @param score {Score}
 * @returns HTMLElement
 */
export function buildScoreListItem(score) {
  const creatorElements = score.creators.composers
    .concat(score.creators.lyricists)
    .map((val) => {
      const creator = document.createElement('creator');
      creator.innerText = val;
      return creator;
    });

  const instrumentElements = score.instruments.map((val) => {
    const instrument = document.createElement('instrument');
    instrument.innerText = val;
    return instrument;
  });

  const tagElements = score.tags.map((val) => {
    const tag = document.createElement('tag');
    tag.innerText = val;
    return tag;
  });

  const creators = document.createElement('creators');
  for (const creator of creatorElements) {
    creators.appendChild(creator);
  }

  const instruments = document.createElement('instruments');
  for (const instrument of instrumentElements) {
    instruments.appendChild(instrument);
  }

  const tags = document.createElement('tags');
  for (const tag of tagElements) {
    tags.appendChild(tag);
  }

  const scoreListItem = document.createElement('score-list-item');
  scoreListItem.appendChild(creators);
  scoreListItem.appendChild(instruments);
  scoreListItem.appendChild(tags);
  scoreListItem.setAttribute('title', score.work.title ?? score.movement.title);

  scoreListItem.onclick = () => {
    window.location.href = `http://localhost:3000#/scores/${score.id}`;
  }

  return scoreListItem;
}

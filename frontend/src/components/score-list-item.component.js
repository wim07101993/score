import {Score} from '../data/database/models.js';
import {getListProperty} from '../data/html-functions.js';

export function registerScoreListItem() {
  class ScoreListItem extends HTMLElement {
    constructor() {
      super();

      const container = document.createElement('div');
      container.id = 'container';
      container.appendChild(this.buildTitle());
      container.appendChild(this.buildCreators());
      container.appendChild(this.buildInstruments());
      container.appendChild(this.buildTags());

      const shadow = this.attachShadow({mode: 'open'});
      shadow.appendChild(this.buildStyle());
      shadow.appendChild(container);
    }

    buildTitle() {
      const title = document.createElement('h2');
      title.innerText = this.getAttribute('title');
      return title;
    }

    /**
     * @param svgAsset {string}
     * @param alt {string}
     * @returns {HTMLImageElement}
     */
    buildIcon(svgAsset, alt) {
      const artistIcon = document.createElement('img');
      artistIcon.setAttribute('src', svgAsset);
      artistIcon.setAttribute('class', 'icon');
      artistIcon.setAttribute('alt', alt);
      return artistIcon
    }

    buildCreators() {
      const icon = this.buildIcon('assets/icons/artist.svg', 'Creators: ')

      const creatorsSpan = document.createElement('span');
      creatorsSpan.innerText = getListProperty(this, 'creators', 'creator').join(', ');

      const creators = document.createElement('p');
      creators.id = 'creators';
      creators.classList.add('score-property');
      creators.appendChild(icon);
      creators.appendChild(creatorsSpan)
      return creators;
    }

    buildInstruments() {
      const icon = this.buildIcon('assets/icons/instruments.svg', 'Instruments: ')

      const instrumentsSpan = document.createElement('span');
      instrumentsSpan.innerText = getListProperty(this, 'instruments', 'instrument').join(' ,');
      console.log(instrumentsSpan.innerText);

      const instruments = document.createElement('p');
      instruments.id = 'instruments';
      instruments.classList.add('score-property');
      instruments.appendChild(icon);
      instruments.appendChild(instrumentsSpan);
      return instruments;
    }

    buildTags() {
      const tags = document.createElement('p');
      tags.id = 'tags';
      tags.classList.add('score-property');
      tags.innerText = getListProperty(this, 'tags', 'tag').join(', ');
      return tags;
    }

    buildStyle() {
      const style = document.createElement('style')
      style.textContent = `
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
        `;
      return style;
    }
  }

  customElements.define('score-list-item', ScoreListItem);
}

/**
 * @param score {Score}
 * @returns HTMLElement
 */
export function buildScoreListItem(score) {
  const creatorElements = score.creators.map((val) => {
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

  const element = document.createElement('div');
  element.appendChild(scoreListItem);
  element.onclick = () => {
    window.location.href = `http://localhost:3000#/scores/${score.id}`;
  }
  return element;
}

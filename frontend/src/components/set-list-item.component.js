/**
 * One set in the list of sets.
 *
 * Everything it shows is an attribute rather than a child element: a set has no
 * list-shaped property to show here, so there is nothing for the child-tag
 * protocol {@link buildScoreListItem} needs to buy.
 */
export function registerSetListItem() {
  class SetListItem extends HTMLElement {
    static titleAttributeName = 'title';
    static descriptionAttributeName = 'description';
    static entriesAttributeName = 'entries';
    static stateAttributeName = 'state';

    static get observedAttributes() {
      return [
        SetListItem.titleAttributeName,
        SetListItem.descriptionAttributeName,
        SetListItem.entriesAttributeName,
        SetListItem.stateAttributeName,
      ];
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
            margin-top: 0;
            margin-bottom: 0;
        }

        #description {
            margin-top: 4px;
            margin-bottom: 0;
        }

        #footer {
            margin-top: 8px;
            margin-bottom: 0;
            display: flex;
            gap: 8px;
            align-items: center;
        }

        #state {
            border-radius: 10px;
            padding: 1px 8px;
            background-color: var(--second-background);
            font-size: 0.8rem;
        }
        #state:empty {
            display: none;
        }
      </style>
      <div id="container">
        <h2 id="title"></h2>
        <p id="description"></p>
        <p id="footer">
          <span id="entries"></span>
          <span id="state"></span>
        </p>
      </div>
      `;
    }

    connectedCallback() {
      this.updateProperties();
    }

    attributeChangedCallback() {
      this.updateProperties();
    }

    updateProperties() {
      const title = this.getAttribute(SetListItem.titleAttributeName) ?? '';
      this.shadow.getElementById('title').innerText = title.trim() === '' ? 'Untitled set' : title;

      const description = this.shadow.getElementById('description');
      description.innerText = this.getAttribute(SetListItem.descriptionAttributeName) ?? '';
      description.hidden = description.innerText.trim() === '';

      const entries = Number(this.getAttribute(SetListItem.entriesAttributeName) ?? 0);
      this.shadow.getElementById('entries').innerText =
        entries === 1 ? '1 score' : `${entries} scores`;

      this.shadow.getElementById('state').innerText =
        this.getAttribute(SetListItem.stateAttributeName) ?? '';
    }
  }

  customElements.define('set-list-item', SetListItem);
}

/**
 * @param set {import('../domains/sets/database.js').ScoreSet}
 * @returns {HTMLElement}
 */
export function buildSetListItem(set) {
  const item = document.createElement('set-list-item');
  item.setAttribute('title', set.title ?? '');
  item.setAttribute('description', set.description ?? '');
  item.setAttribute('entries', `${set.entries?.length ?? 0}`);
  item.setAttribute('state', stateOf(set));

  item.onclick = () => {
    const search = new URLSearchParams({'id': set.id}).toString();
    window.location = `detail.html?${search}`;
  };

  return item;
}

/**
 * What is worth saying about a set beyond what it holds: whose it is, and
 * whether the server has heard about it yet. A set that is still owed to the
 * server is playable all the same, which is the point, but saying so is what
 * keeps "I edited that" and "the others can see it" apart.
 *
 * @param set {import('../domains/sets/database.js').ScoreSet}
 * @returns {string}
 */
function stateOf(set) {
  if (set.is_owner === false) {
    return 'shared with you';
  }
  if (set.pending_change != null) {
    return 'not sent yet';
  }
  if (set.shared_with?.length > 0) {
    return `shared with ${set.shared_with.length}`;
  }
  return '';
}

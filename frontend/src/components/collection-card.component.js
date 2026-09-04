import {LitElement, html, nothing} from "../packages/lit-core.3.3.3.min.js";

/**
 * One collection in the list of collections: what the group of pieces is, what
 * it is about, how much is in it, and whether anybody else has it yet.
 *
 * Light DOM and one whole-card link, for the same reasons as
 * {@link import('./score-card.component.js').ScoreCard}.
 */
export class CollectionCard extends LitElement {
  static properties = {
    collection: {type: Object},
  };

  createRenderRoot() {
    return this;
  }

  render() {
    if (this.collection == null) {
      return nothing;
    }

    const title = (this.collection.title ?? '').trim();
    const description = (this.collection.description ?? '').trim();
    const entries = this.collection.entries?.length ?? 0;
    const state = stateOf(this.collection);

    return html`
      <a class="collection-card"
         href="detail.html?${new URLSearchParams({id: this.collection.id}).toString()}">
        <h2 class="collection-card-title">
          ${title === '' ? 'Untitled collection' : title}
        </h2>
        ${description === '' ? nothing : html`
          <p class="collection-card-description">${description}</p>`}
        <p class="collection-card-footer">
          <span class="muted">${entries === 1 ? '1 piece' : `${entries} pieces`}</span>
          ${state === '' ? nothing : html`<span class="chip">${state}</span>`}
        </p>
      </a>`;
  }
}

customElements.define('collection-card', CollectionCard);

/**
 * @param collection {import('../domains/collections/database.js').Collection}
 * @return {HTMLElement}
 */
export function buildCollectionCard(collection) {
  const card = document.createElement('collection-card');
  card.collection = collection;
  return card;
}

/**
 * What is worth saying about a collection beyond what it holds: whose it is,
 * and whether the server has heard about it yet. One that is still owed to the
 * server can be read from all the same, which is the point, but saying so is
 * what keeps "I added that" and "the others can see it" apart.
 *
 * @param collection {import('../domains/collections/database.js').Collection}
 * @return {string}
 */
function stateOf(collection) {
  if (collection.is_owner === false) {
    return 'shared with you';
  }
  if (collection.pending_change != null) {
    return 'not sent yet';
  }
  if (collection.shared_with?.length > 0) {
    return `shared with ${collection.shared_with.length}`;
  }
  return '';
}

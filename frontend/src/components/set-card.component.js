import {LitElement, html, nothing} from "../packages/lit-core.3.3.3.min.js";

/**
 * One set in the list of sets: the gig, what it is about, how much is in it,
 * and whether anybody else has it yet.
 *
 * Light DOM and one whole-card link, for the same reasons as
 * {@link import('./score-card.component.js').ScoreCard}.
 */
export class SetCard extends LitElement {
  static properties = {
    set: {type: Object},
  };

  createRenderRoot() {
    return this;
  }

  render() {
    if (this.set == null) {
      return nothing;
    }

    const title = (this.set.title ?? '').trim();
    const description = (this.set.description ?? '').trim();
    const entries = this.set.entries?.length ?? 0;
    const state = stateOf(this.set);

    return html`
      <a class="set-card" href="detail.html?${new URLSearchParams({id: this.set.id}).toString()}">
        <h2 class="set-card-title">${title === '' ? 'Untitled set' : title}</h2>
        ${description === '' ? nothing : html`
          <p class="set-card-description">${description}</p>`}
        <p class="set-card-footer">
          <span class="muted">${entries === 1 ? '1 score' : `${entries} scores`}</span>
          ${state === '' ? nothing : html`<span class="chip">${state}</span>`}
        </p>
      </a>`;
  }
}

customElements.define('set-card', SetCard);

/**
 * @param set {import('../domains/sets/database.js').ScoreSet}
 * @return {HTMLElement}
 */
export function buildSetCard(set) {
  const card = document.createElement('set-card');
  card.set = set;
  return card;
}

/**
 * What is worth saying about a set beyond what it holds: whose it is, and
 * whether the server has heard about it yet. A set that is still owed to the
 * server is playable all the same, which is the point, but saying so is what
 * keeps "I edited that" and "the others can see it" apart.
 *
 * @param set {import('../domains/sets/database.js').ScoreSet}
 * @return {string}
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

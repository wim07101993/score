import {getInstrumentName} from "../data/translations.js";

/**
 * Who wrote a score, what it is written for, and what it is filed under.
 *
 * These are the score's own words, not the words of whatever is holding it: a
 * piece is by the same composer whether it is read out of a set, out of a
 * collection, or out of the list of scores it was picked from. That is why this
 * lives here rather than beside either page — a running order is a gig and a
 * collection is a book, and the two are told apart everywhere except here, in
 * the handful of words that belong to the piece.
 *
 * Nothing at all for a song played from paper or one this device has not got:
 * there is no score to say any of it, and a line of blanks under a title says
 * less than no line.
 *
 * @param score {Object|null}
 * @return {HTMLElement[]}
 */
export function buildScoreDetails(score) {
  if (score == null) {
    return [];
  }

  const said = [];

  // Who wrote it and what it is for, said on one line. Under a title there is
  // no room for a label per fact, and the two read as one sentence anyway.
  const creators = [...(score.creators?.composers ?? []), ...(score.creators?.lyricists ?? [])]
    .join(', ');
  const instruments = (score.instruments ?? []).map((one) => getInstrumentName(one)).join(', ');
  const meta = [creators, instruments].filter((part) => part !== '');
  if (meta.length > 0) {
    const line = document.createElement('span');
    line.className = 'score-meta';
    line.innerText = meta.join(' · ');
    said.push(line);
  }

  const tags = score.tags ?? [];
  if (tags.length > 0) {
    const chips = document.createElement('span');
    chips.className = 'score-tags';
    for (const tag of tags) {
      const chip = document.createElement('span');
      chip.className = 'chip';
      chip.innerText = tag;
      chips.appendChild(chip);
    }
    said.push(chips);
  }

  return said;
}

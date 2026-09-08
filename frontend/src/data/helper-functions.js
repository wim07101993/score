import {getInstrumentName} from "./translations.js";

/**
 * @param parent {HTMLElement}
 * @param listTag {string}
 * @param elementTag {string}
 * @returns {string[]}
 */
export function getListProperty(parent, listTag, elementTag) {
  /**
   * @type {string[]}
   */
  const values = []
  for (const listElement of parent.getElementsByTagName(listTag)) {
    for (const element of listElement.getElementsByTagName(elementTag)) {
      values.push(element.innerHTML);
    }
  }
  return values;
}

/**
 * What to call a score.
 *
 * A score is titled by the work it is part of, and by the movement when the
 * work has no title of its own — a document that only ever names one of the two
 * is common enough that a score with no title at all is worth being ready for.
 *
 * @param score {Object|null}
 * @returns {string}
 */
export function getScoreTitle(score) {
  const title = score?.work?.title ?? score?.movement?.title ?? '';
  return `${title}`.trim() === '' ? 'Untitled score' : title;
}

/**
 * Text as searching compares it: in lower case and without its accents.
 *
 * Somebody looking for Fauré's Après un rêve types what their keyboard makes
 * easy, and a search that only matches what the engraver typed is a search that
 * cannot find half the repertoire. It goes both ways — the needle and the score
 * are put through this — so `apres` finds `Après` and `Après` finds a score
 * somebody uploaded as `Apres`.
 *
 * Splitting the accents off the letters they sit on is what normalising to NFD
 * does, which leaves them as marks of their own to drop. Letters that are not
 * an accented anything, such as ø, are left as they are: they are letters, not
 * decorated ones, and no amount of normalising turns one into an o.
 *
 * @param text {string|null|undefined}
 * @return {string}
 */
export function forSearch(text) {
  return `${text ?? ''}`
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLowerCase();
}

/**
 * Everything about a score somebody might look for it by: what it is called,
 * who wrote it, what it is written for, and what it is filed under.
 *
 * Said in the words a page shows rather than the words the document uses — the
 * instruments as their names — so that what is on the screen is what is being
 * searched.
 *
 * @param score {Object|null}
 * @return {string}
 */
export function scoreSearchText(score) {
  return forSearch([
    getScoreTitle(score),
    ...(score?.creators?.composers ?? []),
    ...(score?.creators?.lyricists ?? []),
    ...(score?.instruments ?? []).map((one) => getInstrumentName(one)),
    ...(score?.tags ?? []),
  ].join(' '));
}

/**
 * Whether a score is one of the ones being looked for.
 *
 * Every word has to be found, and each of them anywhere: `beethoven ferne`
 * finds the piece whose composer is one and whose title is the other, which
 * looking for the whole phrase in one field would not. Somebody searching a
 * library types what they remember about a piece, and what they remember is
 * rarely one field of it in the order it is written.
 *
 * Nothing typed is not a search, and everything matches it.
 *
 * @param score {Object|null}
 * @param query {string|null|undefined}
 * @return {boolean}
 */
export function scoreMatches(score, query) {
  const words = forSearch(query).split(/\s+/).filter((word) => word !== '');
  if (words.length === 0) {
    return true;
  }

  const searchable = scoreSearchText(score);
  return words.every((word) => searchable.includes(word));
}

/**
 * Calls the healthz endpoint and returns whether the response is ok.
 *
 * @param healthzEndpoint {URL}
 * @return {Promise<boolean>}
 */
export async function canBeReached(healthzEndpoint) {
  try {
    const response = await fetch(healthzEndpoint)
    return response.ok;
  } catch (error) {
    console.error(`failed to call ${healthzEndpoint}`, error);
    return false;
  }
}

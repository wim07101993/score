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

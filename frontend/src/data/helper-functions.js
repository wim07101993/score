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

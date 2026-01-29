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
 * Calle the healthz endpoint and returns whether the response is ok.
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

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
    for (const element of listElement.getElementsByTagName(elementTag) ) {
      values.push(element.innerHTML);
    }
  }
  return values;
}

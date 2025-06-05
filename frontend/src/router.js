const scoreDetailPageRegex = new RegExp('^#/scores/[A-Za-z0-9]+$');

/**
 * @param route {string} the route to load
 * @returns {string} the content of the page.
 */
export function loadPage(route) {
  console.log(`loading page for route ${route}`)
  if (scoreDetailPageRegex.test(route + '')) {
    console.log('loading score detail page');
    return `<score-detail-page></score-detail-page>`;
  }
  console.log('loading score list page');
  return `<score-list-page></score-list-page>`;
}

class Router {

}

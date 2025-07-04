export class ScoresApi {
  baseUrl =  'http://localhost:7001';

  /**
   * @param changesSince {Date}
   * @param changesUntil {Date}
   * @returns {Promise<Score[]>}
   */
  async getScores(changesSince, changesUntil) {
    const params = new URLSearchParams({
      'Changes-Since': _formatDate(changesSince),
      'Changes-Until': _formatDate(changesUntil),
    });
    const url = `${this.baseUrl}/scores?${params.toString()}`;
    /**
     * @type Response
     */
    const response = await fetch(url)
    if (response.status >= 500) {
      throw `failed to fetch scores (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to fetch scores: ${response.status} ${response.statusText}: ${await response.text()}`;
    }

    return await response.json();
  }

  /**
   * @param scoreId
   * @returns {Promise<Score|null>}
   */
  async getScore(scoreId) {
    const url = `${this.baseUrl}/scores/${scoreId}`;
    /**
     * @type Response
     */
    const response = await fetch(url)
    if (response.status >= 500) {
      throw `failed to fetch score (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to fetch score: ${response.status} ${response.statusText}: ${await response.text()}`;
    }
    return await response.json();
  }
}

/**
 * @param date {Date}
 * @returns {string}
 * @private
 */
function _formatDate(date) {
  return date.toISOString()
    .replaceAll('-', '')
    .replaceAll(':', '')
    .split('.')[0];
}

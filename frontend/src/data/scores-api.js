export class ApiConfig{
  /**
   * @param baseUrl {URL}
   */
  constructor(baseUrl) {
    this.baseUrl = baseUrl;
  }
}

// ----------------------------------------------------------------------------
// API
// ----------------------------------------------------------------------------

export class ScoresApi {
  /**
   * @param config {ApiConfig}
   */
  constructor(config) {
    this.config = config;
  }

  /**
   * @param changesSince {Date}
   * @param changesUntil {Date}
   * @param authToken {String}
   * @returns {Promise<ScoreDto[]>}
   */
  async getScores(changesSince, changesUntil, authToken) {
    const params = new URLSearchParams({
      'Changes-Since': _formatDate(changesSince),
      'Changes-Until': _formatDate(changesUntil),
    });
    const url = `${this.config.baseUrl}scores?${params.toString()}`;
    /**
     * @type Response
     */
    const response = await fetch(url, {
      headers: {
        "Authorization": `Bearer ${authToken}`
      }
    });
    if (response.status >= 500) {
      throw `failed to fetch scores (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to fetch scores: ${response.status} ${response.statusText}: ${await response.text()}`;
    }

    return await response.json();
  }

  /**
   * @param scoreId {String}
   * @param authToken {String}
   * @returns {Promise<Score|null>}
   */
  async getScore(scoreId, authToken) {
    const url = `${this.config.baseUrl}scores/${scoreId}`;
    /**
     * @type Response
     */
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept': 'application/json'
      }
    });
    if (response.status >= 500) {
      throw `failed to fetch score (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to fetch score: ${response.status} ${response.statusText}: ${await response.text()}`;
    }
    return await response.json();
  }

  /**
   * @param scoreId
   * @param authToken
   * @returns {Promise<String>}
   */
  async getScoreMusicxml(scoreId, authToken) {
    const url = `${this.config.baseUrl}scores/${scoreId}`;
    /**
     * @type Response
     */
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept': 'application/vnd.recordare.musicxml'
      }
    });
    if (response.status >= 500) {
      throw `failed to fetch score musicxml (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to fetch score musicxml: ${response.status} ${response.statusText}: ${await response.text()}`;
    }
    return await response.text();
  }
}

// ----------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------------------

export class ScoreDto {
  /**
   * @param {string} id
   * @param {Work|null} work
   * @param {Movement|null} movement
   * @param {Creators} creators
   * @param {string[]} languages
   * @param {string[]} instruments
   * @param {string} last_changed_at
   * @param {string[]} tags
   */
  constructor(id,
              work,
              movement,
              creators,
              languages,
              instruments,
              last_changed_at,
              tags) {
    this.id = id;
    this.work = work;
    this.movement = movement;
    this.creators = creators;
    this.languages = languages;
    this.instruments = instruments;
    this.last_changed_at = last_changed_at;
    this.tags = tags;
  }
}

export class MovementDto {
  /**
   * @param {string|null} title
   * @param {bigint|null} number
   */
  constructor(title, number) {
    this.title = title;
    this.number = number;
  }
}

export class WorkDto {
  /**
   * @param {string|null} title
   * @param {bigint|null} number
   */
  constructor(title, number) {
    this.title = title;
    this.number = number;
  }
}

export class CreatorsDto {
  /**
   * @param {string[]} composers
   * @param {string[]} lyricists
   */
  constructor(composers, lyricists) {
    this.composers = composers;
    this.lyricists = lyricists;
  }
}

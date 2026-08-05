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
      'Changes-Since': _formatDate(changesSince ?? new Date(0)),
      'Changes-Until': _formatDate(_ceilToSecond(changesUntil ?? new Date())),
    });
    const url = `${this.config.baseUrl}scores?${params.toString()}`;
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
   * The metadata of one score, asked for by id.
   *
   * A listing only ever answers with what changed inside a window, so it is no
   * way to get hold of a score that is older than the window a client has left
   * to ask about. This is: it answers whatever is stored under the id,
   * whenever it last changed. `null` when there is nothing stored under it.
   *
   * @param scoreId {String}
   * @param authToken {String}
   * @returns {Promise<ScoreDto|null>}
   */
  async getScore(scoreId, authToken) {
    const url = `${this.config.baseUrl}scores/${scoreId}`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept': 'application/json'
      }
    });
    if (response.status === 404) {
      return null;
    }
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

  /**
   * @param scoreId {string}
   * @param authToken {string}
   * @param musicXml {string}
   * @return {Promise<void>}
   */
  async putScore(scoreId, authToken, musicXml) {
    const url = `${this.config.baseUrl}scores/${scoreId}`;
    const response = await fetch(url,  {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/vnd.recordare.musicxml'
      },
      body: musicXml
    });
    if (response.status >= 500) {
      throw `failed to update score (server error): ${response.status} ${response.statusText}: ${await response.text()}`;
    } else if (response.status >= 400) {
      throw `failed to update score:  ${response.status} ${response.statusText}: ${await response.text()}`;
    }
  }

  async canBeReached() {
    const response = await fetch(`${this.config.baseUrl}healthz`);
    return response.ok;
  }
}

// ----------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------

/**
 * Writes a moment the way the API reads it, which is to the second. Anything
 * finer is dropped, so this rounds down.
 *
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

/**
 * The first whole second at or after the given moment.
 *
 * This is what the end of a change window needs, because the API keeps
 * everything that changed up to and including the moment it is given. Rounding
 * the end down instead leaves out whatever changed during the second that is
 * still running, which is exactly what a client that has just uploaded a score
 * is asking after.
 *
 * @param date {Date}
 * @returns {Date}
 * @private
 */
function _ceilToSecond(date) {
  return new Date(Math.ceil(date.getTime() / 1000) * 1000);
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
   * @param {Date} last_changed_at
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

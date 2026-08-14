/**
 * The sets endpoints of the API.
 *
 * Unlike the scores endpoints, these are written to as well as read from, and a
 * write is made from an edit that was already accepted and stored on this
 * device. So a failure has to say more than that it failed: whether the write
 * is worth trying again decides between keeping the edit queued and giving it
 * up, and that is what {@link SetsApiError} carries.
 */

// ----------------------------------------------------------------------------
// FAILURES
// ----------------------------------------------------------------------------

/**
 * A call that did not come back with what was asked for.
 *
 * The status is the one http gave, and `errorCode` the one this API gives —
 * which is the one to branch on, the way
 * [the API says](../../../../api/schemas/problem_details.yaml). Both are absent
 * when the call never reached a server at all.
 */
export class SetsApiError extends Error {
  /**
   * @param message {string}
   * @param status {number|null}
   * @param problem {Object|null} the RFC 9457 body, when there was one
   * @param cause {Error|null}
   */
  constructor(message, status, problem = null, cause = null) {
    super(message, cause == null ? undefined : {cause});
    this.name = 'SetsApiError';
    this.status = status;
    this.problem = problem;
    this.errorCode = problem?.errorCode ?? null;
  }

  /**
   * Whether the same call is worth making again later.
   *
   * A request the server refused to read is refused just as firmly the next
   * time: a set naming a score that does not exist, or an address that is not
   * an address, is not going to start being accepted because time passed. What
   * is worth trying again is everything that says nothing about the request —
   * the network being down, the server being unwell, a token that has run out.
   *
   * @return {boolean}
   */
  get isWorthRetrying() {
    if (this.status == null) {
      // Nothing answered, so nothing has been said about the request.
      return true;
    }
    if (this.errorCode === 'not_set_owner') {
      // The set belongs to someone else, and waiting does not change whose it
      // is.
      return false;
    }
    if (this.status === 401 || this.status === 403) {
      // A token that expired mid-sync, or a role that has yet to be granted:
      // both are about the caller rather than about what was written.
      return true;
    }
    return this.status < 400 || this.status >= 500;
  }
}

// ----------------------------------------------------------------------------
// API
// ----------------------------------------------------------------------------

export class SetsApi {
  /**
   * @param config {import('../scores/api.js').ApiConfig}
   */
  constructor(config) {
    this.config = config;
  }

  /**
   * The sets that changed within the window, the caller's own and the ones
   * shared with them, most recently changed first. Sets that were deleted
   * within it come back too, with `deleted_at` filled in.
   *
   * @param changesSince {Date|null}
   * @param changesUntil {Date|null}
   * @param authToken {string}
   * @returns {Promise<SetDto[]>}
   */
  async listSets(changesSince, changesUntil, authToken) {
    const params = new URLSearchParams({
      'Changes-Since': _formatDate(changesSince ?? new Date(0)),
      'Changes-Until': _formatDate(changesUntil ?? new Date()),
    });
    const response = await _call(`${this.config.baseUrl}sets?${params.toString()}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept': 'application/json',
      },
    }, 'list the sets');
    await _throwUnlessOk(response, 'list the sets');
    return await response.json();
  }

  /**
   * One set, asked for by id. `null` when there is no such set, or when it is
   * neither the caller's nor shared with them.
   *
   * A listing only ever answers with what changed inside a window, so this is
   * the only way to get hold of a set that is older than the window a client
   * has left to ask about.
   *
   * @param setId {string}
   * @param authToken {string}
   * @returns {Promise<SetDto|null>}
   */
  async getSet(setId, authToken) {
    const response = await _call(`${this.config.baseUrl}sets/${setId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept': 'application/json',
      },
    }, 'fetch the set');
    if (response.status === 404) {
      return null;
    }
    await _throwUnlessOk(response, 'fetch the set');
    return await response.json();
  }

  /**
   * Stores what the set is — the gig, and who may read it — under the given id,
   * and hands back the set as it now reads.
   *
   * What is played in it is not written here and is not touched by writing
   * here: an entry is a resource of its own, put into the set and taken out
   * again one at a time. So a set is created empty and filled afterwards, and
   * correcting a title never restates the running order.
   *
   * @param setId {string}
   * @param authToken {string}
   * @param writeSet {WriteSetDto}
   * @returns {Promise<SetDto>}
   */
  async putSet(setId, authToken, writeSet) {
    const response = await _call(`${this.config.baseUrl}sets/${setId}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(writeSet),
    }, 'save the set');
    await _throwUnlessOk(response, 'save the set');
    return await response.json();
  }

  /**
   * Puts one score into a set, or changes how it is played, and hands the entry
   * back as it now reads — including where in the running order it ended up.
   *
   * An entry is written on its own because a set is not rewritten to change one
   * song in it: a client that added a song sends that song, and a client
   * catching up after a gig it spent offline sends what it changed rather than
   * a running order that may have moved on without it.
   *
   * @param setId {string}
   * @param entryId {string}
   * @param authToken {string}
   * @param writeEntry {WriteSetEntryDto}
   * @returns {Promise<SetEntryDto>}
   */
  async putEntry(setId, entryId, authToken, writeEntry) {
    const response = await _call(`${this.config.baseUrl}sets/${setId}/entries/${entryId}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(writeEntry),
    }, 'save the entry');
    await _throwUnlessOk(response, 'save the entry');
    return await response.json();
  }

  /**
   * Takes one score out of a set. An entry that is already gone is not an
   * error: what was asked for is the state it is now in.
   *
   * @param setId {string}
   * @param entryId {string}
   * @param authToken {string}
   * @returns {Promise<void>}
   */
  async deleteEntry(setId, entryId, authToken) {
    const response = await _call(`${this.config.baseUrl}sets/${setId}/entries/${entryId}`, {
      method: 'DELETE',
      headers: {'Authorization': `Bearer ${authToken}`},
    }, 'delete the entry');
    if (response.status === 404) {
      return;
    }
    await _throwUnlessOk(response, 'delete the entry');
  }

  /**
   * Stores how the caller looks at one entry of a set, and hands it back as it
   * now reads.
   *
   * Anyone who can read the set can write their own view of its entries: it
   * says nothing about the set and changes nothing anybody else sees, so a
   * player who cannot change a note of the running order can still say how they
   * read it.
   *
   * @param setId {string}
   * @param entryId {string}
   * @param authToken {string}
   * @param writeView {WriteEntryViewDto}
   * @returns {Promise<EntryViewDto>}
   */
  async putEntryView(setId, entryId, authToken, writeView) {
    const response = await _call(`${this.config.baseUrl}sets/${setId}/entries/${entryId}/view`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(writeView),
    }, 'save the view');
    await _throwUnlessOk(response, 'save the view');
    return await response.json();
  }

  /**
   * Marks the set as deleted. A set that was already gone is not an error: what
   * was asked for is the state it is now in.
   *
   * @param setId {string}
   * @param authToken {string}
   * @returns {Promise<void>}
   */
  async deleteSet(setId, authToken) {
    const response = await _call(`${this.config.baseUrl}sets/${setId}`, {
      method: 'DELETE',
      headers: {'Authorization': `Bearer ${authToken}`},
    }, 'delete the set');
    if (response.status === 404) {
      return;
    }
    await _throwUnlessOk(response, 'delete the set');
  }

  async canBeReached() {
    try {
      const response = await fetch(`${this.config.baseUrl}healthz`);
      return response.ok;
    } catch (error) {
      console.error('failed to reach the api', error);
      return false;
    }
  }
}

// ----------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------

/**
 * Makes the call, turning a network that is not there into the same kind of
 * failure as a server that said no — one with no status, since nothing answered.
 *
 * @param url {string}
 * @param options {Object}
 * @param what {string} what was being done, for the message
 * @returns {Promise<Response>}
 * @private
 */
async function _call(url, options, what) {
  try {
    return await fetch(url, options);
  } catch (error) {
    throw new SetsApiError(`failed to ${what}: ${error}`, null, null, error);
  }
}

/**
 * @param response {Response}
 * @param what {string}
 * @returns {Promise<void>}
 * @private
 */
async function _throwUnlessOk(response, what) {
  if (response.ok) {
    return;
  }

  const body = await response.text();
  let problem = null;
  try {
    const parsed = JSON.parse(body);
    // Every failure this API answers with is an RFC 9457 object; anything else
    // came from something in between that does not know about it.
    problem = parsed != null && typeof parsed === 'object' ? parsed : null;
  } catch {
    problem = null;
  }

  throw new SetsApiError(
    `failed to ${what}: ${response.status} ${response.statusText}: ${body}`,
    response.status,
    problem);
}

/**
 * Writes a moment the way the API reads it: RFC 3339, in UTC, keeping the
 * milliseconds, so that a window ends exactly where it was asked to.
 *
 * @param date {Date}
 * @returns {string}
 * @private
 */
function _formatDate(date) {
  return date.toISOString();
}

// ----------------------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------------------

export class SetDto {
  /**
   * @param {string} id
   * @param {string} title
   * @param {string} description
   * @param {SetEntryDto[]} entries in playing order
   * @param {string[]} shared_with only filled in for the owner
   * @param {boolean} is_owner
   * @param {string} last_changed_at
   * @param {string|null} deleted_at
   */
  constructor(id,
              title,
              description,
              entries,
              shared_with,
              is_owner,
              last_changed_at,
              deleted_at) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.entries = entries;
    this.shared_with = shared_with;
    this.is_owner = is_owner;
    this.last_changed_at = last_changed_at;
    this.deleted_at = deleted_at;
  }
}

export class SetEntryDto {
  /**
   * Everything here but `view` is the same for everyone the set is shared
   * with: it is what the band does, and it is the owner's to say.
   *
   * @param {string} id the entry's for as long as it is in the set, a rewrite
   *   of the set included
   * @param {string|null} score_id the score that is played, and null for a song
   *   that has none — one that is played off paper
   * @param {string} description
   * @param {number} transposition how far the band plays this one from where
   *   it is written, in semitones, negative for down
   * @param {EntryViewDto} view how the caller looks at it, which is theirs
   *   alone
   */
  constructor(id, score_id, description, transposition, view) {
    this.id = id;
    this.score_id = score_id;
    this.description = description;
    this.transposition = transposition;
    this.view = view;
  }
}

export class EntryViewDto {
  /**
   * @param {number} transposition on top of the entry's rather than instead of
   *   it: the entry says the band plays this one a tone down, this says the
   *   player reads that a fifth up
   * @param {string[]} hidden_parts the parts this player has off screen
   * @param {number} zoom how big this player draws it, where 1 is the size it
   *   is written at
   */
  constructor(transposition, hidden_parts, zoom = 1) {
    this.transposition = transposition;
    this.hidden_parts = hidden_parts;
    this.zoom = zoom;
  }
}

export class WriteEntryViewDto {
  /**
   * @param {number} transposition
   * @param {string[]} hidden_parts
   * @param {number} zoom
   */
  constructor(transposition, hidden_parts, zoom = 1) {
    this.transposition = transposition;
    this.hidden_parts = hidden_parts;
    this.zoom = zoom;
  }
}

export class WriteSetDto {
  /**
   * What a set is: the gig, and who may read it. What is played in it is not
   * here — an entry is written on its own — so a set is created empty and
   * filled afterwards, and correcting a title is correcting a title.
   *
   * @param {string} title
   * @param {string} description
   * @param {string[]} shared_with
   */
  constructor(title, description, shared_with) {
    this.title = title;
    this.description = description;
    this.shared_with = shared_with;
  }
}

export class WriteSetEntryDto {
  /**
   * What the band does with one score, and nothing about how anybody looks at
   * it: a view belongs to a player rather than to a set, and is written on its
   * own. So writing an entry leaves every player's view of it alone, this
   * client's user included.
   *
   * Which entry it is, is not here either: it is named in the path.
   *
   * @param {string|null} score_id the score that is played, and null for a song
   *   that is played off paper
   * @param {string} description
   * @param {number} transposition how far the band plays it from where it is
   *   written
   * @param {number} position where in the running order it goes, counting from
   *   zero. The set is closed up around it, and a place beyond the end of the
   *   set is the end of the set rather than a refusal.
   */
  constructor(score_id, description, transposition, position) {
    this.score_id = score_id;
    this.description = description;
    this.transposition = transposition;
    this.position = position;
  }
}

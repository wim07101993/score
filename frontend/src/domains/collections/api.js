/**
 * The collections endpoints of the API.
 *
 * A collection is the other way the music is grouped: a book, a band's
 * repertoire — the pieces belong together, nothing says which comes first, and
 * a piece is in it or it is not. Everything about talking to the server is the
 * same as it is for a set, for the same reason: a write is made from an edit
 * that was already accepted and stored on this device, so a failure has to say
 * more than that it failed. Whether the write is worth trying again decides
 * between keeping the edit queued and giving it up, and that is what
 * {@link CollectionsApiError} carries.
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
export class CollectionsApiError extends Error {
  /**
   * @param message {string}
   * @param status {number|null}
   * @param problem {Object|null} the RFC 9457 body, when there was one
   * @param cause {Error|null}
   */
  constructor(message, status, problem = null, cause = null) {
    super(message, cause == null ? undefined : {cause});
    this.name = 'CollectionsApiError';
    this.status = status;
    this.problem = problem;
    this.errorCode = problem?.errorCode ?? null;
  }

  /**
   * Whether the same call is worth making again later.
   *
   * A request the server refused to read is refused just as firmly the next
   * time: a collection naming a score that does not exist, or an address that
   * is not an address, is not going to start being accepted because time
   * passed. What is worth trying again is everything that says nothing about
   * the request — the network being down, the server being unwell, a token that
   * has run out.
   *
   * @return {boolean}
   */
  get isWorthRetrying() {
    if (this.status == null) {
      // Nothing answered, so nothing has been said about the request.
      return true;
    }
    if (this.errorCode === 'not_collection_owner') {
      // The collection belongs to someone else, and waiting does not change
      // whose it is.
      return false;
    }
    if (this.status === 401 || this.status === 403) {
      // A token that expired mid-sync, or a role that has yet to be granted:
      // both are about the caller rather than about what was written.
      return true;
    }
    return this.status < 400 || this.status >= 500;
  }

  /**
   * Whether this is the collection saying it already holds the piece.
   *
   * It is the one refusal a set has no equivalent of, and the only one that is
   * worth acting on rather than reporting: the piece the client was trying to
   * add is in the collection, which is what it wanted. What it is in is
   * {@link alreadyInEntryId}.
   *
   * @return {boolean}
   */
  get isAlreadyInTheCollection() {
    return this.errorCode === 'score_already_in_collection';
  }

  /**
   * The entry the piece is already in, when that is what went wrong.
   *
   * @return {string|null}
   */
  get alreadyInEntryId() {
    return this.isAlreadyInTheCollection ? this.problem?.entryId ?? null : null;
  }
}

// ----------------------------------------------------------------------------
// API
// ----------------------------------------------------------------------------

export class CollectionsApi {
  /**
   * @param config {import('../scores/api.js').ApiConfig}
   */
  constructor(config) {
    this.config = config;
  }

  /**
   * The collections that changed within the window, the caller's own and the
   * ones shared with them, most recently changed first. Collections that were
   * deleted within it come back too, with `deleted_at` filled in.
   *
   * @param changesSince {Date|null}
   * @param changesUntil {Date|null}
   * @param authToken {string}
   * @returns {Promise<CollectionDto[]>}
   */
  async listCollections(changesSince, changesUntil, authToken) {
    const params = new URLSearchParams({
      'Changes-Since': _formatDate(changesSince ?? new Date(0)),
      'Changes-Until': _formatDate(changesUntil ?? new Date()),
    });
    const response = await _call(`${this.config.baseUrl}collections?${params.toString()}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept': 'application/json',
      },
    }, 'list the collections');
    await _throwUnlessOk(response, 'list the collections');
    return await response.json();
  }

  /**
   * One collection, asked for by id. `null` when there is no such collection,
   * or when it is neither the caller's nor shared with them.
   *
   * A listing only ever answers with what changed inside a window, so this is
   * the only way to get hold of a collection that is older than the window a
   * client has left to ask about.
   *
   * @param collectionId {string}
   * @param authToken {string}
   * @returns {Promise<CollectionDto|null>}
   */
  async getCollection(collectionId, authToken) {
    const response = await _call(`${this.config.baseUrl}collections/${collectionId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Accept': 'application/json',
      },
    }, 'fetch the collection');
    if (response.status === 404) {
      return null;
    }
    await _throwUnlessOk(response, 'fetch the collection');
    return await response.json();
  }

  /**
   * Stores what the collection is — the group of pieces, and who may read it —
   * under the given id, and hands back the collection as it now reads.
   *
   * What is in it is not written here and is not touched by writing here: an
   * entry is a resource of its own, put into the collection and taken out again
   * one at a time.
   *
   * @param collectionId {string}
   * @param authToken {string}
   * @param writeCollection {WriteCollectionDto}
   * @returns {Promise<CollectionDto>}
   */
  async putCollection(collectionId, authToken, writeCollection) {
    const response = await _call(`${this.config.baseUrl}collections/${collectionId}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(writeCollection),
    }, 'save the collection');
    await _throwUnlessOk(response, 'save the collection');
    return await response.json();
  }

  /**
   * Puts one piece into a collection, or changes what the group does with it,
   * and hands the entry back as it now reads.
   *
   * A collection holds a piece once: an entry naming a score that is already in
   * it under another entry comes back as a
   * {@link CollectionsApiError#isAlreadyInTheCollection} refusal, carrying the
   * entry it is already in.
   *
   * @param collectionId {string}
   * @param entryId {string}
   * @param authToken {string}
   * @param writeEntry {WriteCollectionEntryDto}
   * @returns {Promise<CollectionEntryDto>}
   */
  async putEntry(collectionId, entryId, authToken, writeEntry) {
    const response = await _call(
      `${this.config.baseUrl}collections/${collectionId}/entries/${entryId}`, {
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
   * Takes one piece out of a collection. An entry that is already gone is not
   * an error: what was asked for is the state it is now in.
   *
   * @param collectionId {string}
   * @param entryId {string}
   * @param authToken {string}
   * @returns {Promise<void>}
   */
  async deleteEntry(collectionId, entryId, authToken) {
    const response = await _call(
      `${this.config.baseUrl}collections/${collectionId}/entries/${entryId}`, {
        method: 'DELETE',
        headers: {'Authorization': `Bearer ${authToken}`},
      }, 'delete the entry');
    if (response.status === 404) {
      return;
    }
    await _throwUnlessOk(response, 'delete the entry');
  }

  /**
   * Stores how the caller looks at one entry of a collection, and hands it back
   * as it now reads.
   *
   * Anyone who can read the collection can write their own view of its entries:
   * it says nothing about the collection and changes nothing anybody else sees,
   * so a player who cannot add a piece to the book can still say how they read
   * one that is in it.
   *
   * @param collectionId {string}
   * @param entryId {string}
   * @param authToken {string}
   * @param writeView {WriteEntryViewDto}
   * @returns {Promise<EntryViewDto>}
   */
  async putEntryView(collectionId, entryId, authToken, writeView) {
    const response = await _call(
      `${this.config.baseUrl}collections/${collectionId}/entries/${entryId}/view`, {
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
   * Marks the collection as deleted. One that was already gone is not an error:
   * what was asked for is the state it is now in.
   *
   * @param collectionId {string}
   * @param authToken {string}
   * @returns {Promise<void>}
   */
  async deleteCollection(collectionId, authToken) {
    const response = await _call(`${this.config.baseUrl}collections/${collectionId}`, {
      method: 'DELETE',
      headers: {'Authorization': `Bearer ${authToken}`},
    }, 'delete the collection');
    if (response.status === 404) {
      return;
    }
    await _throwUnlessOk(response, 'delete the collection');
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
 * failure as a server that said no — one with no status, since nothing
 * answered.
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
    throw new CollectionsApiError(`failed to ${what}: ${error}`, null, null, error);
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

  throw new CollectionsApiError(
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

export class CollectionDto {
  /**
   * @param {string} id
   * @param {string} title
   * @param {string} description
   * @param {CollectionEntryDto[]} entries by title; a collection has no order
   *   of its own
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

export class CollectionEntryDto {
  /**
   * Everything here but `view` is the same for everyone the collection is
   * shared with: it is what the group does with the piece, and it is the
   * owner's to say.
   *
   * @param {string} id the entry's for as long as it is in the collection
   * @param {string|null} score_id the piece, and null for one that is in the
   *   collection but not in here — a page of a book nobody has scanned
   * @param {string} description
   * @param {number} transposition how far the group plays this one from where
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
   *   it
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

export class WriteCollectionDto {
  /**
   * What a collection is: the group of pieces, and who may read it. What is in
   * it is not here — an entry is written on its own — so a collection is
   * created empty and filled afterwards.
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

export class WriteCollectionEntryDto {
  /**
   * What the group does with one piece, and nothing about how anybody looks at
   * it: a view belongs to a player rather than to a collection, and is written
   * on its own.
   *
   * Which entry it is, is not here either: it is named in the path. Where it
   * comes in the collection is nowhere at all — a collection has no order.
   *
   * @param {string|null} score_id the piece, and null for one that is in the
   *   collection but not in here
   * @param {string} description
   * @param {number} transposition how far the group plays it from where it is
   *   written
   */
  constructor(score_id, description, transposition) {
    this.score_id = score_id;
    this.description = description;
    this.transposition = transposition;
  }
}

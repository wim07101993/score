/**
 * Where the collections are kept between visits.
 *
 * The same reasoning as the sets: a collection is looked at and added to on the
 * device it is played from, which is where there is no network, so an edit is
 * stored here first and sent afterwards. That makes this the truth for as long
 * as it takes a write to reach the API — what is in here is what the player
 * sees, whether or not the server has heard of it yet.
 *
 * It is a database of its own rather than a store in the sets one, so that
 * adding it asks nothing of a client that already has sets cached: an upgrade
 * of the sets database would have to run before any set could be read again.
 */

export const ObjectStoreName = Object.freeze({
  Collections: 'collections'
});

/** What a collection is waiting to have done to it on the server. */
export const PendingChange = Object.freeze({
  /** Nothing: what is here is what the server last said. */
  None: null,
  /** It was written here and the write has not reached the server yet. */
  Write: 'write',
  /** It was deleted here and the delete has not reached the server yet. */
  Delete: 'delete',
});

export class CollectionDatabase {
  /**
   * @type IDBDatabase
   */
  database;

  /**
   * @return {Promise<void>}
   */
  async open() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('collections', 1);

      request.onerror = (event) => reject(event.target.error);
      request.onsuccess = (event) => {
        this.database = event.target.result;
        return resolve();
      };

      request.onupgradeneeded = (event) => {
        console.log(`upgrade needed from version ${event.oldVersion} to ${event.newVersion}`, event);
        const db = event.target.result;

        if (!db.objectStoreNames.contains(ObjectStoreName.Collections)) {
          const store = db.createObjectStore(ObjectStoreName.Collections, {
            keyPath: 'id',
            autoIncrement: false
          });
          console.log(`created ${store.name} store`);
        }
      };
    });
  }

  /**
   * Every collection that is kept here, the deleted ones included: one that is
   * gone is kept as a headstone so that a sync knows not to fetch it back.
   *
   * @returns {Promise<Collection[]>}
   */
  async fetchCollections() {
    return new Promise((resolve, reject) => {
      const request = this.database
        .transaction([ObjectStoreName.Collections])
        .objectStore(ObjectStoreName.Collections)
        .getAll();

      request.onerror = (event) => reject(event.target.error);
      request.onsuccess = (event) => resolve(event.target.result);
    });
  }

  /**
   * @param {Collection[]} collections
   * @returns {Promise<void>}
   */
  async saveCollections(collections) {
    const transaction = this.database.transaction(ObjectStoreName.Collections, 'readwrite');
    const store = transaction.objectStore(ObjectStoreName.Collections);
    const transactionCompletePromise = new Promise((resolve, reject) => {
      transaction.oncomplete = () => resolve();
      transaction.onerror = (event) => reject(event);
      transaction.onabort = (event) => reject(event);
    });

    for (const collection of collections) {
      store.put(collection);
    }

    await transactionCompletePromise;
  }

  /**
   * @param {Collection} collection
   * @returns {Promise<void>}
   */
  async saveCollection(collection) {
    await this.saveCollections([collection]);
  }
}

// ----------------------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------------------

/**
 * A collection as this app keeps it: what the API says a collection is, plus
 * what only this device knows — when it last heard from the server about it,
 * and what it still owes the server.
 *
 * A collection is a group of scores that belong together without being played
 * in any particular order: the pieces a book holds, the repertoire a band can
 * be asked for. It is the other half of what a set is — a set is a gig, where
 * the same song may come round twice and the order is what is played, while
 * here order says nothing and a score is in it or it is not.
 */
export class Collection {
  /**
   * @param {string} id
   * @param {string} title
   * @param {string} description
   * @param {CollectionEntry[]} entries the pieces in it. They come back by
   *   title rather than in an order the collection has, because it has none.
   * @param {string[]} shared_with the addresses it is readable by; only ever
   *   filled in for the owner
   * @param {boolean} is_owner whether it is this user's to change
   * @param {Date} last_changed_at when it was last written, here or there
   * @param {Date|null} deleted_at when it was deleted, or null while it exists
   * @param {Date|null} last_synced_at when the server last said what is above
   * @param {string|null} pending_change one of {@link PendingChange}
   * @param {string[]} pending_views the entries whose view this user has
   *   written here and the server has not heard about yet. A view is written by
   *   whoever it belongs to rather than by the owner, so it is owed separately:
   *   a player who cannot add a piece to the book still has their own reading
   *   of one that is in it to send.
   * @param {{id: string, action: string}[]} pending_entries what has been done
   *   to the collection here and not sent yet, in the order it was done.
   *   Entries are written one at a time, so what is owed is one piece at a time
   *   rather than the whole book.
   */
  constructor(id,
              title,
              description,
              entries,
              shared_with,
              is_owner,
              last_changed_at,
              deleted_at,
              last_synced_at,
              pending_change,
              pending_views = [],
              pending_entries = []) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.entries = entries;
    this.shared_with = shared_with;
    this.is_owner = is_owner;
    this.last_changed_at = last_changed_at;
    this.deleted_at = deleted_at;
    this.last_synced_at = last_synced_at;
    this.pending_change = pending_change;
    this.pending_views = pending_views;
    this.pending_entries = pending_entries;
  }
}

export class CollectionEntry {
  /**
   * Everything here but the view is what the group does with the piece, which
   * is the same for everyone the collection is shared with and the owner's to
   * say.
   *
   * There is no position. Where a piece comes in a collection is not a thing a
   * collection has an answer to.
   *
   * @param {string} id what this entry is called, here and on the server. An
   *   entry added here is named here, and the server keeps the name, which is
   *   what lets a player put a piece in and say how they read it before either
   *   has been sent anywhere.
   * @param {string|null} score_id the piece, and null for one that is in the
   *   collection but not in here. A score is in a collection at most once; the
   *   pieces that have none are outside that rule, since they are told apart by
   *   what is written next to them.
   * @param {string} description
   * @param {number} transposition how far the group plays this one from where
   *   it is written, in semitones, negative for down
   * @param {EntryView} view how this user looks at it, which is theirs alone
   * @param {boolean} synced whether the server has this entry. An entry that
   *   was added here and never sent is nothing to tell the server about when it
   *   is taken out again: there is no row there to remove.
   */
  constructor(id, score_id, description, transposition, view, synced = false) {
    this.id = id;
    this.score_id = score_id;
    this.description = description;
    this.transposition = transposition;
    this.view = view;
    this.synced = synced;
  }
}

/**
 * How one player looks at one entry: on top of the key the group plays it in,
 * which parts they have on screen, and how big they draw it.
 *
 * An entry nobody has looked at differently has the view every entry starts
 * with: as written, every part on screen.
 */
export class EntryView {
  /**
   * @param {number} transposition semitones on top of the entry's own
   * @param {string[]} hidden_parts by MusicXML part id
   * @param {number} zoom how big this player draws it, where 1 is the size it
   *   is written at
   */
  constructor(transposition = 0, hidden_parts = [], zoom = 1) {
    this.transposition = transposition;
    this.hidden_parts = hidden_parts;
    this.zoom = zoom;
  }
}

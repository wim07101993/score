/**
 * Where the sets are kept between visits.
 *
 * A set is edited on the device it is played from, and a gig is exactly where
 * there is no network, so an edit is stored here first and sent afterwards.
 * That makes this the truth for as long as it takes a write to reach the API:
 * what is in here is what the player sees, whether or not the server has heard
 * of it yet.
 *
 * It is a database of its own rather than a second store in the scores one, so
 * that adding it asks nothing of a client that already has scores cached: an
 * upgrade of the scores database would have to run before any score could be
 * read again.
 */

export const ObjectStoreName = Object.freeze({
  Sets: 'sets'
});

/** What a set is waiting to have done to it on the server. */
export const PendingChange = Object.freeze({
  /** Nothing: what is here is what the server last said. */
  None: null,
  /** It was written here and the write has not reached the server yet. */
  Write: 'write',
  /** It was deleted here and the delete has not reached the server yet. */
  Delete: 'delete',
});

export class SetDatabase {
  /**
   * @type IDBDatabase
   */
  database;

  /**
   * @return {Promise<void>}
   */
  async open() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('sets', 1);

      request.onerror = (event) => reject(event.target.error);
      request.onsuccess = (event) => {
        this.database = event.target.result;
        return resolve();
      };

      request.onupgradeneeded = (event) => {
        console.log(`upgrade needed from version ${event.oldVersion} to ${event.newVersion}`, event);
        const db = event.target.result;

        if (!db.objectStoreNames.contains(ObjectStoreName.Sets)) {
          const store = db.createObjectStore(ObjectStoreName.Sets, {
            keyPath: 'id',
            autoIncrement: false
          });
          console.log(`created ${store.name} store`);
        }
      };
    });
  }

  /**
   * Every set that is kept here, the deleted ones included: a set that is gone
   * is kept as a headstone so that a sync knows not to fetch it back.
   *
   * @returns {Promise<ScoreSet[]>}
   */
  async fetchSets() {
    return new Promise((resolve, reject) => {
      const request = this.database
        .transaction([ObjectStoreName.Sets])
        .objectStore(ObjectStoreName.Sets)
        .getAll();

      request.onerror = (event) => reject(event.target.error);
      request.onsuccess = (event) => resolve(event.target.result);
    });
  }

  /**
   * @param {ScoreSet[]} sets
   * @returns {Promise<void>}
   */
  async saveSets(sets) {
    const transaction = this.database.transaction(ObjectStoreName.Sets, 'readwrite');
    const store = transaction.objectStore(ObjectStoreName.Sets);
    const transactionCompletePromise = new Promise((resolve, reject) => {
      transaction.oncomplete = () => resolve();
      transaction.onerror = (event) => reject(event);
      transaction.onabort = (event) => reject(event);
    });

    for (const set of sets) {
      store.put(set);
    }

    await transactionCompletePromise;
  }

  /**
   * @param {ScoreSet} set
   * @returns {Promise<void>}
   */
  async saveSet(set) {
    await this.saveSets([set]);
  }
}

// ----------------------------------------------------------------------------
// MODELS
// ----------------------------------------------------------------------------

/**
 * A set as this app keeps it: what the API says a set is, plus what only this
 * device knows — when it last heard from the server about it, and what it still
 * owes the server.
 *
 * It is called a `ScoreSet` rather than a `Set` because the other one is taken.
 */
export class ScoreSet {
  /**
   * @param {string} id
   * @param {string} title
   * @param {string} description
   * @param {SetEntry[]} entries in playing order
   * @param {string[]} shared_with the addresses it is readable by; only ever
   *   filled in for the owner
   * @param {boolean} is_owner whether it is this user's to change
   * @param {Date} last_changed_at when it was last written, here or there
   * @param {Date|null} deleted_at when it was deleted, or null while it exists
   * @param {Date|null} last_synced_at when the server last said what is above
   * @param {string|null} pending_change one of {@link PendingChange}
   * @param {string[]} pending_views the entries whose view this user has
   *   written here and the server has not heard about yet. A view is written by
   *   whoever it belongs to rather than by the owner of the set, so it is owed
   *   separately from the set: a player who cannot change a note of the running
   *   order still has their own reading of it to send.
   * @param {{id: string, action: string}[]} pending_entries what has been done
   *   to the running order here and not sent yet, in the order it was done.
   *   Entries are written one at a time, so what is owed is one song at a time
   *   rather than the whole list: a client that added a song at a gig sends
   *   that song, and nothing it says can undo what somebody else did to the
   *   rest of the set in the meantime.
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

export class SetEntry {
  /**
   * Everything here but the view is what the band does, which is the same for
   * everyone the set is shared with and the owner's to say.
   *
   * @param {string} id what this entry is called, here and on the server. An
   *   entry keeps its id across a write of the set, which is what lets a view
   *   of it go on pointing at the same thing; an entry added here is named
   *   here, and the server keeps the name.
   * @param {string} score_id
   * @param {string} description
   * @param {number} transposition how far the band plays this one from where
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
 * How one player looks at one entry: on top of the key the band plays it in,
 * and which parts they have on screen.
 *
 * The saxophone player reading their part a sixth up changes nothing for the
 * pianist, and the pianist wanting the piano staff alone changes nothing for
 * the singer. An entry nobody has looked at differently has the view every
 * entry starts with: as written, every part on screen.
 */
export class EntryView {
  /**
   * @param {number} transposition semitones on top of the entry's own
   * @param {string[]} hidden_parts by MusicXML part id
   */
  constructor(transposition = 0, hidden_parts = []) {
    this.transposition = transposition;
    this.hidden_parts = hidden_parts;
  }
}

export class Score {
  /**
   * @param {string} id
   * @param {Work|null} work
   * @param {Movement|null} movement
   * @param {Creators} creators
   * @param {string[]} languages
   * @param {string[]} instruments
   * @param {Date} last_changed_at
   * @param {string[]} tags
   * @param {Date|null} last_fetched_file_at
   */
  constructor(id,
              work,
              movement,
              creators,
              languages,
              instruments,
              last_changed_at,
              tags,
              last_fetched_file_at) {
    this.id = id;
    this.work = work;
    this.movement = movement;
    this.creators = creators;
    this.languages = languages;
    this.instruments = instruments;
    this.last_changed_at = last_changed_at;
    this.tags = tags;
    this.last_fetched_file_at = last_fetched_file_at;
  }
}

export class Movement {
  /**
   * @param {string|null} title
   * @param {bigint|null} number
   */
  constructor(title, number) {
    this.title = title;
    this.number = number;
  }
}

export class Work {
  /**
   * @param {string|null} title
   * @param {bigint|null} number
   */
  constructor(title, number) {
    this.title = title;
    this.number = number;
  }
}

export class Creators {
  /**
   * @param {string[]} composers
   * @param {string[]} lyricists
   */
  constructor(composers, lyricists) {
    this.composers = composers;
    this.lyricists = lyricists;
  }
}

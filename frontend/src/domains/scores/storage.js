export class MusicXmlStorage {
  /**
   * @param scoreId {String}
   * @param musicxml {String}
   * @returns {Promise<void>}
   */
  static async save(scoreId, musicxml) {
    await navigator.storage.persist();
    const dir = await navigator.storage.getDirectory();
    const filename = MusicXmlStorage._getFileNameForScoreId(scoreId);
    const fileHandle = await dir.getFileHandle(filename, {create: true});
    const file = await fileHandle.createWritable({keepExistingData: false})
    try {
      await file.write(musicxml);
    } finally {
      await file.close();
    }
  }

  static async exists(scoreId) {
    await navigator.storage.persist();
    const dir = await navigator.storage.getDirectory();
    const filename = MusicXmlStorage._getFileNameForScoreId(scoreId);
    for await (const [_, value] of dir.entries()) {
      if (value.name === filename) {
        return true;
      }
    }
    return false;
  }

  /**
   * @param scoreId {String}
   * @returns {Promise<String>}
   */
  static async get(scoreId) {
    await navigator.storage.persist();
    const dir = await navigator.storage.getDirectory();
    const filename = MusicXmlStorage._getFileNameForScoreId(scoreId);
    const fileHandle = await dir.getFileHandle(filename, {
      create: false,
    });
    const file = await fileHandle.getFile();
    return await file.text();
  }

  /**
   * @param scoreId {String}
   * @return {string}
   */
  static _getFileNameForScoreId(scoreId) {
    return `scores_${scoreId}.musicxml`;
  }
}

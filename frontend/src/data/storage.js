/**
 * @param id {String}
 * @param musicxml {String}
 * @returns {Promise<void>}
 */
export async function saveMusicxml(id, musicxml) {
  await navigator.storage.persist();
  const dir = await navigator.storage.getDirectory();
  const fileHandle = await dir.getFileHandle(`${id}.musicxml`, {
    create: true,
  });
  const file = await fileHandle.createWritable({
    keepExistingData: false
  })
  try {
    await file.write(musicxml);
  } finally {
    await file.close();
  }
}

export async function musicxmlExists(id) {
  await navigator.storage.persist();
  const dir = await navigator.storage.getDirectory();
  for await (const [_, value] of dir.entries()) {
    if (value.name === `${id}.musicxml`) {
      return true;
    }
  }
  return false;
}

/**
 * @param id {String}
 * @returns {Promise<String>}
 */
export async function getMusicxml(id) {
  await navigator.storage.persist();
  const dir = await navigator.storage.getDirectory();
  const fileHandle = await dir.getFileHandle(`${id}.musicxml`, {
    create: false,
  });
  const file = await fileHandle.getFile();
  return await file.text();
}

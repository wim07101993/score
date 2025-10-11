/**
 *
 * @param instrument {String} the instrument to get the name of.
 * @returns {String} the human-readable instrument name.
 */
export function getInstrumentName(instrument) {
  switch (instrument.toLowerCase()) {
    case 'brass.french-horn': return 'french horn';
    case 'brass.trumpet': return 'trumpet';
    case 'brass.trombone.tenor': return 'trombone';
    case 'brass.tuba': return 'tuba';
    case 'keyboard.celesta': return 'celesta';
    case 'keyboard.organ.pipe': return 'pipe organ';
    case 'keyboard.piano': return 'piano';
    case 'keyboard.piano.grand': return 'grand piano';
    case 'pluck.harp': return 'harp';
    case 'pluck.guitar.electric': return 'electric guitar';
    case 'pluck.guitar.nylon-string': return 'classical guitar';
    case 'pluck.guitar.steel-string': return 'acoustic guitar';
    case 'pluck.bass.electric': return 'bass guitar';
    case 'strings.cello': return 'cello';
    case 'strings.contrabass': return 'contrabass';
    case 'strings.violin': return 'flute';
    case 'strings.viola': return 'viola';
    case 'voice.vocals': return 'voice';
    case 'wind.flutes.flute': return 'flute';
    case 'wind.reed.bassoon': return 'bassoon';
    case 'wind.reed.clarinet': return 'clarinet';
    case 'wind.reed.clarinet.bass': return 'bass clarinet';
    case 'wind.reed.english-horn': return 'english horn';
    case 'wind.reed.oboe': return 'oboe';
    case 'wind.reed.saxophone.alto': return 'alto saxophone';
    case 'wind.reed.saxophone.mezzo-soprano': return 'mezzo soprano saxophone';
    case 'wind.reed.saxophone.soprano': return 'soprano saxophone';
    case 'wind.reed.saxophone.tenor': return 'tenor';
  }
  return instrument;
}

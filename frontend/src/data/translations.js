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
    case 'strings.violin': return 'violin';
    case 'strings.viola': return 'viola';
    case 'voice.vocals': return 'vocals';
    case 'voice.soprano': return 'soprano';
    case 'voice.alto': return 'alto';
    case 'voice.tenor': return 'tenor';
    case 'voice.bass': return 'bass';
    case 'wind.flutes.flute': return 'flute';
    case 'wind.reed.bassoon': return 'bassoon';
    case 'wind.reed.clarinet': return 'clarinet';
    case 'wind.reed.clarinet.bass': return 'bass clarinet';
    case 'wind.reed.english-horn': return 'english horn';
    case 'wind.reed.oboe': return 'oboe';
    case 'wind.reed.saxophone.alto': return 'alto saxophone';
    case 'wind.reed.saxophone.mezzo-soprano': return 'mezzo soprano saxophone';
    case 'wind.reed.saxophone.soprano': return 'soprano saxophone';
    case 'wind.reed.saxophone.tenor': return 'tenor saxophone';
  }
  return instrument;
}

/**
 * The formatter, made once. Building one per row of a list is measurable on a
 * library of any size, and it says the same thing every time.
 *
 * @type {Intl.DisplayNames|null}
 */
let languageNames = null;

/**
 * What a language is called, said the way the reader's own device says it.
 *
 * The codes come out of the document itself — the language the lyrics are
 * marked as — so they are whatever the person who engraved it typed. One that
 * means nothing to anybody is handed back as it came rather than dropped: a
 * row that said nothing where a language belongs would read as a piece with no
 * words at all.
 *
 * @param language {String} a language tag, such as `nl` or `en-GB`
 * @returns {String} empty only when there was no tag to name
 */
export function getLanguageName(language) {
  if (typeof language !== 'string' || language.trim() === '') {
    return '';
  }

  const tag = language.trim();
  try {
    if (languageNames == null) {
      languageNames = new Intl.DisplayNames(undefined, {type: 'language'});
    }
    return languageNames.of(tag) ?? tag;
  } catch (error) {
    // A tag that is not shaped like one at all makes Intl throw rather than
    // shrug, and the tag itself is still the best thing there is to show.
    return tag;
  }
}

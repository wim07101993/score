/// What to call an instrument.
///
/// MusicXML names them by a sound code, which is precise and is not what a
/// player calls the thing they hold. Anything not named here is shown as it was
/// written: a code a reader has to work out beats a name that is wrong.
library;

const Map<String, String> _names = {
  'brass.french-horn': 'french horn',
  'brass.trumpet': 'trumpet',
  'brass.trombone.tenor': 'trombone',
  'brass.tuba': 'tuba',
  'keyboard.celesta': 'celesta',
  'keyboard.organ.pipe': 'pipe organ',
  'keyboard.piano': 'piano',
  'keyboard.piano.grand': 'grand piano',
  'pluck.harp': 'harp',
  'pluck.guitar.electric': 'electric guitar',
  'pluck.guitar.nylon-string': 'classical guitar',
  'pluck.guitar.steel-string': 'acoustic guitar',
  'pluck.bass.electric': 'bass guitar',
  'strings.cello': 'cello',
  'strings.contrabass': 'contrabass',
  'strings.violin': 'violin',
  'strings.viola': 'viola',
  'voice.vocals': 'vocals',
  'voice.soprano': 'soprano',
  'voice.alto': 'alto',
  'voice.tenor': 'tenor',
  'voice.bass': 'bass',
  'wind.flutes.flute': 'flute',
  'wind.reed.bassoon': 'bassoon',
  'wind.reed.clarinet': 'clarinet',
  'wind.reed.clarinet.bass': 'bass clarinet',
  'wind.reed.english-horn': 'english horn',
  'wind.reed.oboe': 'oboe',
  'wind.reed.saxophone.alto': 'alto saxophone',
  'wind.reed.saxophone.mezzo-soprano': 'mezzo soprano saxophone',
  'wind.reed.saxophone.soprano': 'soprano saxophone',
  'wind.reed.saxophone.tenor': 'tenor saxophone',
};

String instrumentName(String instrument) =>
    _names[instrument.toLowerCase()] ?? instrument;

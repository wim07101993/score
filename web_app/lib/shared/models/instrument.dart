enum Instrument {
  unknown,

  // Strings
  guitar,
  bassGuitar,
  violin,
  tenorViolin,
  viola,
  cello,
  doubleBass,
  harp,
  lute,

  // Keys
  piano,
  organ,
  accordion,

  // Woodwind
  flute,
  altoFlute,
  piccolo,
  recorder,
  clarinet,
  altoClarinet,
  bassClarinet,
  bagpipes,
  saxophone,
  sopranoSaxophone,
  altoSaxophone,
  tenorSaxophone,
  baritoneSaxophone,
  bassSaxophone,
  bassoon,
  contrabassoon,
  tenoroon,
  oboe,

  // Copper
  trumpet,
  frenchHorn,
  englishHorn,
  altoHorn,
  baritoneHorn,
  trombone,
  euphonium,
  tuba,

  // Singers
  singer,
  choir,
  sopranoSinger,
  alto,
  tenor,
  baritone,
  bass,

  // Percussion
  tenorDrum,
  bassDrum,
  xylophone;

  factory Instrument.parse(String name) {
    return Instrument.values.firstWhere(
      (instrument) => instrument.name == name,
      orElse: () => Instrument.unknown,
    );
  }
}

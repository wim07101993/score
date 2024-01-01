// ignore: unused_import, always_use_package_imports
import 'aliases.g.dart';

/// The above-below type is used to indicate whether one element appears above or below another element.
enum AboveBelow {
  above,
  below,
}

/// The css-font-size type includes the CSS font sizes used as an alternative to a numeric point size.
enum CssFontSize {
  xxSmall,
  xSmall,
  small,
  medium,
  large,
  xLarge,
  xxLarge,
}

/// The enclosure-shape type describes the shape and presence / absence of an enclosure around text or symbols. A bracket enclosure is similar to a rectangle with the bottom line missing, as is common in jazz notation. An inverted-bracket enclosure is similar to a rectangle with the top line missing.
enum EnclosureShape {
  rectangle,
  square,
  oval,
  circle,
  bracket,
  invertedBracket,
  triangle,
  diamond,
  pentagon,
  hexagon,
  heptagon,
  octagon,
  nonagon,
  decagon,
  none,
}

/// The fermata-shape type represents the shape of the fermata sign. The empty value is equivalent to the normal value.
enum FermataShape {
  normal,
  angled,
  square,
  doubleAngled,
  doubleSquare,
  doubleDot,
  halfCurve,
  curlew,
  none,
}

/// The font-style type represents a simplified version of the CSS font-style property.
enum FontStyle {
  normal,
  italic,
}

/// The font-weight type represents a simplified version of the CSS font-weight property.
enum FontWeight {
  normal,
  bold,
}

/// The left-center-right type is used to define horizontal alignment and text justification.
enum LeftCenterRight {
  left,
  center,
  right,
}

/// The left-right type is used to indicate whether one element appears to the left or the right of another element.
enum LeftRight {
  left,
  right,
}

/// The line-length type distinguishes between different line lengths for doit, falloff, plop, and scoop articulations.
enum LineLength {
  short,
  medium,
  long,
}

/// The line-shape type distinguishes between straight and curved lines.
enum LineShape {
  straight,
  curved,
}

/// The line-type type distinguishes between solid, dashed, dotted, and wavy lines.
enum LineType {
  solid,
  dashed,
  dotted,
  wavy,
}

/// The mute type represents muting for different instruments, including brass, winds, and strings. The on and off values are used for undifferentiated mutes. The remaining values represent specific mutes.
enum Mute {
  on,
  off,
  straight,
  cup,
  harmonNoStem,
  harmonStem,
  bucket,
  plunger,
  hat,
  solotone,
  practice,
  stopMute,
  stopHand,
  echo,
  palm,
}

/// The over-under type is used to indicate whether the tips of curved lines such as slurs and ties are overhand (tips down) or underhand (tips up).
enum OverUnder {
  over,
  under,
}

/// The semi-pitched type represents categories of indefinite pitch for percussion instruments.
enum SemiPitched {
  high,
  mediumHigh,
  medium,
  mediumLow,
  low,
  veryLow,
}

/// The start-note type describes the starting note of trills and mordents for playback, relative to the current note.
enum StartNote {
  upper,
  main,
  below,
}

/// The start-stop type is used for an attribute of musical elements that can either start or stop, such as tuplets.
/// 
/// The values of start and stop refer to how an element appears in musical score order, not in MusicXML document order. An element with a stop attribute may precede the corresponding element with a start attribute within a MusicXML document. This is particularly common in multi-staff music. For example, the stopping point for a tuplet may appear in staff 1 before the starting point for the tuplet appears in staff 2 later in the document.
/// 
/// When multiple elements with the same tag are used within the same note, their order within the MusicXML document should match the musical score order.
enum StartStop {
  start,
  stop,
}

/// The start-stop-continue type is used for an attribute of musical elements that can either start or stop, but also need to refer to an intermediate point in the symbol, as for complex slurs or for formatting of symbols across system breaks.
/// 
/// The values of start, stop, and continue refer to how an element appears in musical score order, not in MusicXML document order. An element with a stop attribute may precede the corresponding element with a start attribute within a MusicXML document. This is particularly common in multi-staff music. For example, the stopping point for a slur may appear in staff 1 before the starting point for the slur appears in staff 2 later in the document.
/// 
/// When multiple elements with the same tag are used within the same note, their order within the MusicXML document should match the musical score order. For example, a note that marks both the end of one slur and the start of a new slur should have the incoming slur element with a type of stop precede the outgoing slur element with a type of start.
enum StartStopContinue {
  start,
  stop,
  continue_,
}

/// The start-stop-single type is used for an attribute of musical elements that can be used for either multi-note or single-note musical elements, as for groupings.
/// 
/// When multiple elements with the same tag are used within the same note, their order within the MusicXML document should match the musical score order.
enum StartStopSingle {
  start,
  stop,
  single,
}

/// The symbol-size type is used to distinguish between full, cue sized, grace cue sized, and oversized symbols.
enum SymbolSize {
  full,
  cue,
  graceCue,
  large,
}

/// The text-direction type is used to adjust and override the Unicode bidirectional text algorithm, similar to the Directionality data category in the W3C Internationalization Tag Set recommendation. Values are ltr (left-to-right embed), rtl (right-to-left embed), lro (left-to-right bidi-override), and rlo (right-to-left bidi-override). The default value is ltr. This type is typically used by applications that store text in left-to-right visual order rather than logical order. Such applications can use the lro value to better communicate with other applications that more fully support bidirectional text.
enum TextDirection {
  ltr,
  rtl,
  lro,
  rlo,
}

/// The tied-type type is used as an attribute of the tied element to specify where the visual representation of a tie begins and ends. A tied element which joins two notes of the same pitch can be specified with tied-type start on the first note and tied-type stop on the second note. To indicate a note should be undamped, use a single tied element with tied-type let-ring. For other ties that are visually attached to a single note, such as a tie leading into or out of a repeated section or coda, use two tied elements on the same note, one start and one stop.
/// 
/// In start-stop cases, ties can add more elements using a continue type. This is typically used to specify the formatting of cross-system ties.
/// 
/// When multiple elements with the same tag are used within the same note, their order within the MusicXML document should match the musical score order. For example, a note with a tie at the end of a first ending should have the tied element with a type of start precede the tied element with a type of stop.
enum TiedType {
  start,
  stop,
  continue_,
  letRing,
}

/// The top-bottom type is used to indicate the top or bottom part of a vertical shape like non-arpeggiate.
enum TopBottom {
  top,
  bottom,
}

/// The tremolo-type is used to distinguish double-note, single-note, and unmeasured tremolos.
enum TremoloType {
  start,
  stop,
  single,
  unmeasured,
}

/// The trill-step type describes the alternating note of trills and mordents for playback, relative to the current note.
enum TrillStep {
  whole,
  half,
  unison,
}

/// The two-note-turn type describes the ending notes of trills and mordents for playback, relative to the current note.
enum TwoNoteTurn {
  whole,
  half,
  none,
}

/// The up-down type is used for the direction of arrows and other pointed symbols like vertical accents, indicating which way the tip is pointing.
enum UpDown {
  up,
  down,
}

/// The upright-inverted type describes the appearance of a fermata element. The value is upright if not specified.
enum UprightInverted {
  upright,
  inverted,
}

/// The valign type is used to indicate vertical alignment to the top, middle, bottom, or baseline of the text. If the text is on multiple lines, baseline alignment refers to the baseline of the lowest line of text. Defaults are implementation-dependent.
enum Valign {
  top,
  middle,
  bottom,
  baseline,
}

/// The valign-image type is used to indicate vertical alignment for images and graphics, so it does not include a baseline value. Defaults are implementation-dependent.
enum ValignImage {
  top,
  middle,
  bottom,
}

/// The yes-no type is used for boolean-like attributes. We cannot use W3C XML Schema booleans due to their restrictions on expression of boolean values.
enum YesNo {
  yes,
  no,
}

/// The cancel-location type is used to indicate where a key signature cancellation appears relative to a new key signature: to the left, to the right, or before the barline and to the left. It is left by default. For mid-measure key elements, a cancel-location of before-barline should be treated like a cancel-location of left.
enum CancelLocation {
  left,
  right,
  beforeBarline,
}

/// The clef-sign type represents the different clef symbols. The jianpu sign indicates that the music that follows should be in jianpu numbered notation, just as the TAB sign indicates that the music that follows should be in tablature notation. Unlike TAB, a jianpu sign does not correspond to a visual clef notation.
/// 
/// The none sign is deprecated as of MusicXML 4.0. Use the clef element's print-object attribute instead. When the none sign is used, notes should be displayed as if in treble clef.
enum ClefSign {
  g,
  f,
  c,
  percussion,
  tab,
  jianpu,
  none,
}

/// The show-frets type indicates whether to show tablature frets as numbers (0, 1, 2) or letters (a, b, c). The default choice is numbers.
enum ShowFrets {
  numbers,
  letters,
}

/// The staff-type value can be ossia, editorial, cue, alternate, or regular. An ossia staff represents music that can be played instead of what appears on the regular staff. An editorial staff also represents musical alternatives, but is created by an editor rather than the composer. It can be used for suggested interpretations or alternatives from other sources. A cue staff represents music from another part. An alternate staff shares the same music as the prior staff, but displayed differently (e.g., treble and bass clef, standard notation and tablature). It is not included in playback. An alternate staff provides more information to an application reading a file than encoding the same music in separate parts, so its use is preferred in this situation if feasible. A regular staff is the standard default staff-type.
enum StaffType {
  ossia,
  editorial,
  cue,
  alternate,
  regular,
}

/// The time-relation type indicates the symbol used to represent the interchangeable aspect of dual time signatures.
enum TimeRelation {
  parentheses,
  bracket,
  equals,
  slash,
  space,
  hyphen,
}

/// The time-separator type indicates how to display the arrangement between the beats and beat-type values in a time signature. The default value is none. The horizontal, diagonal, and vertical values represent horizontal, diagonal lower-left to upper-right, and vertical lines respectively. For these values, the beats and beat-type values are arranged on either side of the separator line. The none value represents no separator with the beats and beat-type arranged vertically. The adjacent value represents no separator with the beats and beat-type arranged horizontally.
enum TimeSeparator {
  none,
  horizontal,
  diagonal,
  vertical,
  adjacent,
}

/// The time-symbol type indicates how to display a time signature. The normal value is the usual fractional display, and is the implied symbol type if none is specified. Other options are the common and cut time symbols, as well as a single number with an implied denominator. The note symbol indicates that the beat-type should be represented with the corresponding downstem note rather than a number. The dotted-note symbol indicates that the beat-type should be represented with a dotted downstem note that corresponds to three times the beat-type value, and a numerator that is one third the beats value.
enum TimeSymbol {
  common,
  cut,
  singleNumber,
  note,
  dottedNote,
  normal,
}

/// The backward-forward type is used to specify repeat directions. The start of the repeat has a forward direction while the end of the repeat has a backward direction.
enum BackwardForward {
  backward,
  forward,
}

/// The bar-style type represents barline style information. Choices are regular, dotted, dashed, heavy, light-light, light-heavy, heavy-light, heavy-heavy, tick (a short stroke through the top line), short (a partial barline between the 2nd and 4th lines), and none.
enum BarStyle {
  regular,
  dotted,
  dashed,
  heavy,
  lightLight,
  lightHeavy,
  heavyLight,
  heavyHeavy,
  tick,
  short,
  none,
}

/// The right-left-middle type is used to specify barline location.
enum RightLeftMiddle {
  right,
  left,
  middle,
}

/// The start-stop-discontinue type is used to specify ending types. Typically, the start type is associated with the left barline of the first measure in an ending. The stop and discontinue types are associated with the right barline of the last measure in an ending. Stop is used when the ending mark concludes with a downward jog, as is typical for first endings. Discontinue is used when there is no downward jog, as is typical for second endings that do not conclude a piece.
enum StartStopDiscontinue {
  start,
  stop,
  discontinue,
}

/// The winged attribute indicates whether the repeat has winged extensions that appear above and below the barline. The straight and curved values represent single wings, while the double-straight and double-curved values represent double wings. The none value indicates no wings and is the default.
enum Winged {
  none,
  straight,
  curved,
  doubleStraight,
  doubleCurved,
}

/// The beater-value type represents pictograms for beaters, mallets, and sticks that do not have different materials represented in the pictogram. The finger and hammer values are in addition to Stone's list.
enum BeaterValue {
  bow,
  chimeHammer,
  coin,
  drumStick,
  finger,
  fingernail,
  fist,
  guiroScraper,
  hammer,
  hand,
  jazzStick,
  knittingNeedle,
  metalHammer,
  slideBrushOnGong,
  snareStick,
  spoonMallet,
  superball,
  triangleBeater,
  triangleBeaterPlain,
  wireBrush,
}

/// The degree-symbol-value type indicates which symbol should be used in specifying a degree.
enum DegreeSymbolValue {
  major,
  minor,
  augmented,
  diminished,
  halfDiminished,
}

/// The degree-type-value type indicates whether the current degree element is an addition, alteration, or subtraction to the kind of the current chord in the harmony element.
enum DegreeTypeValue {
  add,
  alter,
  subtract,
}

/// The effect-value type represents pictograms for sound effect percussion instruments. The cannon, lotus flute, and megaphone values are in addition to Stone's list.
enum EffectValue {
  anvil,
  autoHorn,
  birdWhistle,
  cannon,
  duckCall,
  gunShot,
  klaxonHorn,
  lionsRoar,
  lotusFlute,
  megaphone,
  policeWhistle,
  siren,
  slideWhistle,
  thunderSheet,
  windMachine,
  windWhistle,
}

/// The glass-value type represents pictograms for glass percussion instruments.
enum GlassValue {
  glassHarmonica,
  glassHarp,
  windChimes,
}

/// The harmony-arrangement type indicates how stacked chords and bass notes are displayed within a harmony element. The vertical value specifies that the second element appears below the first. The horizontal value specifies that the second element appears to the right of the first. The diagonal value specifies that the second element appears both below and to the right of the first.
enum HarmonyArrangement {
  vertical,
  horizontal,
  diagonal,
}

/// The harmony-type type differentiates different types of harmonies when alternate harmonies are possible. Explicit harmonies have all note present in the music; implied have some notes missing but implied; alternate represents alternate analyses.
enum HarmonyType {
  explicit,
  implied,
  alternate,
}

/// A kind-value indicates the type of chord. Degree elements can then add, subtract, or alter from these starting points. Values include:
/// 
/// Triads:
/// 	major (major third, perfect fifth)
/// 	minor (minor third, perfect fifth)
/// 	augmented (major third, augmented fifth)
/// 	diminished (minor third, diminished fifth)
/// Sevenths:
/// 	dominant (major triad, minor seventh)
/// 	major-seventh (major triad, major seventh)
/// 	minor-seventh (minor triad, minor seventh)
/// 	diminished-seventh (diminished triad, diminished seventh)
/// 	augmented-seventh (augmented triad, minor seventh)
/// 	half-diminished (diminished triad, minor seventh)
/// 	major-minor (minor triad, major seventh)
/// Sixths:
/// 	major-sixth (major triad, added sixth)
/// 	minor-sixth (minor triad, added sixth)
/// Ninths:
/// 	dominant-ninth (dominant-seventh, major ninth)
/// 	major-ninth (major-seventh, major ninth)
/// 	minor-ninth (minor-seventh, major ninth)
/// 11ths (usually as the basis for alteration):
/// 	dominant-11th (dominant-ninth, perfect 11th)
/// 	major-11th (major-ninth, perfect 11th)
/// 	minor-11th (minor-ninth, perfect 11th)
/// 13ths (usually as the basis for alteration):
/// 	dominant-13th (dominant-11th, major 13th)
/// 	major-13th (major-11th, major 13th)
/// 	minor-13th (minor-11th, major 13th)
/// Suspended:
/// 	suspended-second (major second, perfect fifth)
/// 	suspended-fourth (perfect fourth, perfect fifth)
/// Functional sixths:
/// 	Neapolitan
/// 	Italian
/// 	French
/// 	German
/// Other:
/// 	pedal (pedal-point bass)
/// 	power (perfect fifth)
/// 	Tristan
/// 
/// The "other" kind is used when the harmony is entirely composed of add elements.
/// 
/// The "none" kind is used to explicitly encode absence of chords or functional harmony. In this case, the root, numeral, or function element has no meaning. When using the root or numeral element, the root-step or numeral-step text attribute should be set to the empty string to keep the root or numeral from being displayed.
enum KindValue {
  major,
  minor,
  augmented,
  diminished,
  dominant,
  majorSeventh,
  minorSeventh,
  diminishedSeventh,
  augmentedSeventh,
  halfDiminished,
  majorMinor,
  majorSixth,
  minorSixth,
  dominantNinth,
  majorNinth,
  minorNinth,
  dominant11Th,
  major11Th,
  minor11Th,
  dominant13Th,
  major13Th,
  minor13Th,
  suspendedSecond,
  suspendedFourth,
  neapolitan,
  italian,
  french,
  german,
  pedal,
  power,
  tristan,
  other,
  none,
}

/// The line-end type specifies if there is a jog up or down (or both), an arrow, or nothing at the start or end of a bracket.
enum LineEnd {
  up,
  down,
  both,
  arrow,
  none,
}

/// The measure-numbering-value type describes how measure numbers are displayed on this part: no numbers, numbers every measure, or numbers every system.
enum MeasureNumberingValue {
  none,
  measure,
  system,
}

/// The membrane-value type represents pictograms for membrane percussion instruments.
enum MembraneValue {
  bassDrum,
  bassDrumOnSide,
  bongos,
  chineseTomtom,
  congaDrum,
  cuica,
  gobletDrum,
  indoAmericanTomtom,
  japaneseTomtom,
  militaryDrum,
  snareDrum,
  snareDrumSnaresOff,
  tabla,
  tambourine,
  tenorDrum,
  timbales,
  tomtom,
}

/// The metal-value type represents pictograms for metal percussion instruments. The hi-hat value refers to a pictogram like Stone's high-hat cymbals but without the long vertical line at the bottom.
enum MetalValue {
  agogo,
  almglocken,
  bell,
  bellPlate,
  bellTree,
  brakeDrum,
  cencerro,
  chainRattle,
  chineseCymbal,
  cowbell,
  crashCymbals,
  crotale,
  cymbalTongs,
  domedGong,
  fingerCymbals,
  flexatone,
  gong,
  hiHat,
  highHatCymbals,
  handbell,
  jawHarp,
  jingleBells,
  musicalSaw,
  shellBells,
  sistrum,
  sizzleCymbal,
  sleighBells,
  suspendedCymbal,
  tamTam,
  tamTamWithBeater,
  triangle,
  vietnameseHat,
}

/// The numeral-mode type specifies the mode similar to the mode type, but with a restricted set of values. The different minor values are used to interpret numeral-root values of 6 and 7 when present in a minor key. The harmonic minor value sharpens the 7 and the melodic minor value sharpens both 6 and 7. If a minor mode is used without qualification, either in the mode or numeral-mode elements, natural minor is used.
enum NumeralMode {
  major,
  minor,
  naturalMinor,
  melodicMinor,
  harmonicMinor,
}

/// The on-off type is used for notation elements such as string mutes.
enum OnOff {
  on,
  off,
}

/// The pedal-type simple type is used to distinguish types of pedal directions. The start value indicates the start of a damper pedal, while the sostenuto value indicates the start of a sostenuto pedal. The other values can be used with either the damper or sostenuto pedal. The soft pedal is not included here because there is no special symbol or graphic used for it beyond what can be specified with words and bracket elements.
/// 
/// The change, continue, discontinue, and resume types are used when the line attribute is yes. The change type indicates a pedal lift and retake indicated with an inverted V marking. The continue type allows more precise formatting across system breaks and for more complex pedaling lines. The discontinue type indicates the end of a pedal line that does not include the explicit lift represented by the stop type. The resume type indicates the start of a pedal line that does not include the downstroke represented by the start type. It can be used when a line resumes after being discontinued, or to start a pedal line that is preceded by a text or symbol representation of the pedal.
enum PedalType {
  start,
  stop,
  sostenuto,
  change,
  continue_,
  discontinue,
  resume,
}

/// The pitched-value type represents pictograms for pitched percussion instruments. The chimes and tubular chimes values distinguish the single-line and double-line versions of the pictogram.
enum PitchedValue {
  celesta,
  chimes,
  glockenspiel,
  lithophone,
  mallet,
  marimba,
  steelDrums,
  tubaphone,
  tubularChimes,
  vibraphone,
  xylophone,
}

/// The principal-voice-symbol type represents the type of symbol used to indicate a principal or secondary voice. The "plain" value represents a plain square bracket. The value of "none" is used for analysis markup when the principal-voice element does not have a corresponding appearance in the score.
enum PrincipalVoiceSymbol {
  hauptstimme,
  nebenstimme,
  plain,
  none,
}

/// The staff-divide-symbol type is used for staff division symbols. The down, up, and up-down values correspond to SMuFL code points U+E00B, U+E00C, and U+E00D respectively.
enum StaffDivideSymbol {
  down,
  up,
  upDown,
}

/// The start-stop-change-continue type is used to distinguish types of pedal directions.
enum StartStopChangeContinue {
  start,
  stop,
  change,
  continue_,
}

/// The sync-type type specifies the style that a score following application should use to synchronize an accompaniment with a performer. The none type indicates no synchronization to the performer. The tempo type indicates synchronization based on the performer tempo rather than individual events in the score. The event type indicates synchronization by following the performance of individual events in the score rather than the performer tempo. The mostly-tempo and mostly-event types combine these two approaches, with mostly-tempo giving more weight to tempo and mostly-event giving more weight to performed events. The always-event type provides the strictest synchronization by not being forgiving of missing performed events.
enum SyncType {
  none,
  tempo,
  mostlyTempo,
  mostlyEvent,
  event,
  alwaysEvent,
}

/// The system-relation-number type distinguishes measure numbers that are associated with a system rather than the particular part where the element appears. A value of only-top or only-bottom indicates that the number should appear only on the top or bottom part of the current system, respectively. A value of also-top or also-bottom indicates that the number should appear on both the current part and the top or bottom part of the current system, respectively. If these values appear in a score, when parts are created the number should only appear once in this part, not twice. A value of none indicates that the number is associated only with the current part, not with the system.
enum SystemRelationNumber {
  onlyTop,
  onlyBottom,
  alsoTop,
  alsoBottom,
  none,
}

/// The tip-direction type represents the direction in which the tip of a stick or beater points, using Unicode arrow terminology.
enum TipDirection {
  up,
  down,
  left,
  right,
  northwest,
  northeast,
  southeast,
  southwest,
}

/// The stick-location type represents pictograms for the location of sticks, beaters, or mallets on cymbals, gongs, drums, and other instruments.
enum StickLocation {
  center,
  rim,
  cymbalBell,
  cymbalEdge,
}

/// The stick-material type represents the material being displayed in a stick pictogram.
enum StickMaterial {
  soft,
  medium,
  hard,
  shaded,
  x,
}

/// The stick-type type represents the shape of pictograms where the material in the stick, mallet, or beater is represented in the pictogram.
enum StickType {
  bassDrum,
  doubleBassDrum,
  glockenspiel,
  gum,
  hammer,
  superball,
  timpani,
  wound,
  xylophone,
  yarn,
}

/// The up-down-stop-continue type is used for octave-shift elements, indicating the direction of the shift from their true pitched values because of printing difficulty.
enum UpDownStopContinue {
  up,
  down,
  stop,
  continue_,
}

/// The wedge type is crescendo for the start of a wedge that is closed at the left side, diminuendo for the start of a wedge that is closed on the right side, and stop for the end of a wedge. The continue type is used for formatting wedges over a system break, or for other situations where a single wedge is divided into multiple segments.
enum WedgeType {
  crescendo,
  diminuendo,
  stop,
  continue_,
}

/// The wood-value type represents pictograms for wood percussion instruments. The maraca and maracas values distinguish the one- and two-maraca versions of the pictogram.
enum WoodValue {
  bambooScraper,
  boardClapper,
  cabasa,
  castanets,
  castanetsWithHandle,
  claves,
  footballRattle,
  guiro,
  logDrum,
  maraca,
  maracas,
  quijada,
  rainstick,
  ratchet,
  recoReco,
  sandpaperBlocks,
  slitDrum,
  templeBlock,
  vibraslap,
  whip,
  woodBlock,
}

/// The margin-type type specifies whether margins apply to even page, odd pages, or both.
enum MarginType {
  odd,
  even,
  both,
}

/// The note-size-type type indicates the type of note being defined by a note-size element. The grace-cue type is used for notes of grace-cue size. The grace type is used for notes of cue size that include a grace element. The cue type is used for all other notes with cue size, whether defined explicitly or implicitly via a cue element. The large type is used for notes of large size.
enum NoteSizeType {
  cue,
  grace,
  graceCue,
  large,
}

/// The accidental-value type represents notated accidentals supported by MusicXML. In the MusicXML 2.0 DTD this was a string with values that could be included. The XSD strengthens the data typing to an enumerated list. The quarter- and three-quarters- accidentals are Tartini-style quarter-tone accidentals. The -down and -up accidentals are quarter-tone accidentals that include arrows pointing down or up. The slash- accidentals are used in Turkish classical music. The numbered sharp and flat accidentals are superscripted versions of the accidental signs, used in Turkish folk music. The sori and koron accidentals are microtonal sharp and flat accidentals used in Iranian and Persian music. The other accidental covers accidentals other than those listed here. It is usually used in combination with the smufl attribute to specify a particular SMuFL accidental. The smufl attribute may be used with any accidental value to help specify the appearance of symbols that share the same MusicXML semantics.
enum AccidentalValue {
  sharp,
  natural,
  flat,
  doubleSharp,
  sharpSharp,
  flatFlat,
  naturalSharp,
  naturalFlat,
  quarterFlat,
  quarterSharp,
  threeQuartersFlat,
  threeQuartersSharp,
  sharpDown,
  sharpUp,
  naturalDown,
  naturalUp,
  flatDown,
  flatUp,
  doubleSharpDown,
  doubleSharpUp,
  flatFlatDown,
  flatFlatUp,
  arrowDown,
  arrowUp,
  tripleSharp,
  tripleFlat,
  slashQuarterSharp,
  slashSharp,
  slashFlat,
  doubleSlashFlat,
  sharp1,
  sharp2,
  sharp3,
  sharp5,
  flat1,
  flat2,
  flat3,
  flat4,
  sori,
  koron,
  other,
}

/// The arrow-direction type represents the direction in which an arrow points, using Unicode arrow terminology.
enum ArrowDirection {
  left,
  up,
  right,
  down,
  northwest,
  northeast,
  southeast,
  southwest,
  leftRight,
  upDown,
  northwestSoutheast,
  northeastSouthwest,
  other,
}

/// The arrow-style type represents the style of an arrow, using Unicode arrow terminology. Filled and hollow arrows indicate polygonal single arrows. Paired arrows are duplicate single arrows in the same direction. Combined arrows apply to double direction arrows like left right, indicating that an arrow in one direction should be combined with an arrow in the other direction.
enum ArrowStyle {
  single,
  double,
  filled,
  hollow,
  paired,
  combined,
  other,
}

/// The beam-value type represents the type of beam associated with each of 8 beam levels (up to 1024th notes) available for each note.
enum BeamValue {
  begin,
  continue_,
  end,
  forwardHook,
  backwardHook,
}

/// The bend-shape type distinguishes between the angled bend symbols commonly used in standard notation and the curved bend symbols commonly used in both tablature and standard notation.
enum BendShape {
  angled,
  curved,
}

/// The breath-mark-value type represents the symbol used for a breath mark.
enum BreathMarkValue {
  none,
  comma,
  tick,
  upbow,
  salzedo,
}

/// The caesura-value type represents the shape of the caesura sign.
enum CaesuraValue {
  normal,
  thick,
  short,
  curved,
  single,
  none,
}

/// The circular-arrow type represents the direction in which a circular arrow points, using Unicode arrow terminology.
enum CircularArrow {
  clockwise,
  anticlockwise,
}

/// The fan type represents the type of beam fanning present on a note, used to represent accelerandos and ritardandos.
enum Fan {
  accel,
  rit,
  none,
}

/// The handbell-value type represents the type of handbell technique being notated.
enum HandbellValue {
  belltree,
  damp,
  echo,
  gyro,
  handMartellato,
  malletLift,
  malletTable,
  martellato,
  martellatoLift,
  mutedMartellato,
  pluckLift,
  swing,
}

/// The harmon-closed-location type indicates which portion of the symbol is filled in when the corresponding harmon-closed-value is half.
enum HarmonClosedLocation {
  right,
  bottom,
  left,
  top,
}

/// The harmon-closed-value type represents whether the harmon mute is closed, open, or half-open.
enum HarmonClosedValue {
  yes,
  no,
  half,
}

/// The hole-closed-location type indicates which portion of the hole is filled in when the corresponding hole-closed-value is half.
enum HoleClosedLocation {
  right,
  bottom,
  left,
  top,
}

/// The hole-closed-value type represents whether the hole is closed, open, or half-open.
enum HoleClosedValue {
  yes,
  no,
  half,
}

/// The note-type-value type is used for the MusicXML type element and represents the graphic note type, from 1024th (shortest) to maxima (longest).
enum NoteTypeValue {
  n1024Th,
  n512Th,
  n256Th,
  n128Th,
  n64Th,
  n32Nd,
  n16Th,
  eighth,
  quarter,
  half,
  whole,
  breve,
  long,
  maxima,
}

/// 
/// The notehead-value type indicates shapes other than the open and closed ovals associated with note durations. 
/// 
/// The values do, re, mi, fa, fa up, so, la, and ti correspond to Aikin's 7-shape system.  The fa up shape is typically used with upstems; the fa shape is typically used with downstems or no stems.
/// 
/// The arrow shapes differ from triangle and inverted triangle by being centered on the stem. Slashed and back slashed notes include both the normal notehead and a slash. The triangle shape has the tip of the triangle pointing up; the inverted triangle shape has the tip of the triangle pointing down. The left triangle shape is a right triangle with the hypotenuse facing up and to the left.
/// 
/// The other notehead covers noteheads other than those listed here. It is usually used in combination with the smufl attribute to specify a particular SMuFL notehead. The smufl attribute may be used with any notehead value to help specify the appearance of symbols that share the same MusicXML semantics. Noteheads in the SMuFL Note name noteheads and Note name noteheads supplement ranges (U+E150–U+E1AF and U+EEE0–U+EEFF) should not use the smufl attribute or the "other" value, but instead use the notehead-text element.
enum NoteheadValue {
  slash,
  triangle,
  diamond,
  square,
  cross,
  x,
  circleX,
  invertedTriangle,
  arrowDown,
  arrowUp,
  circled,
  slashed,
  backSlashed,
  normal,
  cluster,
  circleDot,
  leftTriangle,
  rectangle,
  none,
  do_,
  re,
  mi,
  fa,
  faUp,
  so,
  la,
  ti,
  other,
}

/// The show-tuplet type indicates whether to show a part of a tuplet relating to the tuplet-actual element, both the tuplet-actual and tuplet-normal elements, or neither.
enum ShowTuplet {
  actual,
  both,
  none,
}

/// The stem-value type represents the notated stem direction.
enum StemValue {
  down,
  up,
  double,
  none,
}

/// The step type represents a step of the diatonic scale, represented using the English letters A through G.
enum Step {
  a,
  b,
  c,
  d,
  e,
  f,
  g,
}

/// Lyric hyphenation is indicated by the syllabic type. The single, begin, end, and middle values represent single-syllable words, word-beginning syllables, word-ending syllables, and mid-word syllables, respectively.
enum Syllabic {
  single,
  begin,
  end,
  middle,
}

/// The tap-hand type represents the symbol to use for a tap element. The left and right values refer to the SMuFL guitarLeftHandTapping and guitarRightHandTapping glyphs respectively.
enum TapHand {
  left,
  right,
}

/// The group-barline-value type indicates if the group should have common barlines.
enum GroupBarlineValue {
  yes,
  no,
  mensurstrich,
}

/// The group-symbol-value type indicates how the symbol for a group or multi-staff part is indicated in the score.
enum GroupSymbolValue {
  none,
  brace,
  line,
  bracket,
  square,
}


// ignore_for_file: unused_import, always_use_package_imports, camel_case_types
import 'barrel.g.dart';
enum above-below {
  above,
  above,
}
/// 
/// min inclusive: 1
typedef beam-level = int;
/// 
/// pattern: #[\dA-F]{6}([\dA-F][\dA-F])?
typedef color = String;
/// 
/// pattern: [^,]+(, ?[^,]+)*
typedef comma-separated-text = String;
enum css-font-size {
  xx-small,
  xx-small,
  xx-small,
  xx-small,
  xx-small,
  xx-small,
  xx-small,
}
typedef divisions = double;
enum enclosure-shape {
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
  rectangle,
}
enum fermata-shape {
  normal,
  normal,
  normal,
  normal,
  normal,
  normal,
  normal,
  normal,
  normal,
}
typedef font-family = CommaSeparatedText;
sealed class font-size {
  const factory font-size.xs:decimal(xs:decimal value) = font-size_xs:decimal;
  const factory font-size.cssFontSize(css-font-size value) = font-size_css-font-size;
}

class font-size_xs:decimal implements font-size {
  const font-size_xs:decimal(this.value);

  final xs:decimal value;
}
class font-size_css-font-size implements font-size {
  const font-size_css-font-size(this.value);

  final css-font-size value;
}
enum font-style {
  normal,
  normal,
}
enum font-weight {
  normal,
  normal,
}
enum left-center-right {
  left,
  left,
  left,
}
enum left-right {
  left,
  left,
}
enum line-length {
  short,
  short,
  short,
}
enum line-shape {
  straight,
  straight,
}
enum line-type {
  solid,
  solid,
  solid,
  solid,
}
/// 
/// min inclusive: 1
typedef midi-16 = int;
/// 
/// min inclusive: 1
typedef midi-128 = int;
/// 
/// min inclusive: 1
typedef midi-16384 = int;
enum mute {
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
  on,
}
/// 
/// min inclusive: 0
typedef non-negative-decimal = double;
/// 
/// min inclusive: 1
typedef number-level = int;
/// 
/// min inclusive: 0
typedef number-of-lines = int;
sealed class number-or-normal {
  const factory number-or-normal.xs:decimal(xs:decimal value) = number-or-normal_xs:decimal;
  const factory number-or-normal.numberOrNormalChoiceType(number-or-normal-choice-type value) = number-or-normal_number-or-normal-choice-type;
}

class number-or-normal_xs:decimal implements number-or-normal {
  const number-or-normal_xs:decimal(this.value);

  final xs:decimal value;
}
class number-or-normal_number-or-normal-choice-type implements number-or-normal {
  const number-or-normal_number-or-normal-choice-type(this.value);

  final number-or-normal-choice-type value;
}
/// 
/// min inclusive: 1
typedef numeral-value = int;
enum over-under {
  over,
  over,
}
/// 
/// min inclusive: 0
typedef percent = double;
/// 
/// min exclusive: 0
typedef positive-decimal = double;
/// 
/// min exclusive: 0
typedef positive-divisions = Divisions;
sealed class positive-integer-or-empty {
  const factory positive-integer-or-empty.xs:positiveInteger(xs:positiveInteger value) = positive-integer-or-empty_xs:positiveInteger;
  const factory positive-integer-or-empty.positiveIntegerOrEmptyChoiceType(positive-integer-or-empty-choice-type value) = positive-integer-or-empty_positive-integer-or-empty-choice-type;
}

class positive-integer-or-empty_xs:positiveInteger implements positive-integer-or-empty {
  const positive-integer-or-empty_xs:positiveInteger(this.value);

  final xs:positiveInteger value;
}
class positive-integer-or-empty_positive-integer-or-empty-choice-type implements positive-integer-or-empty {
  const positive-integer-or-empty_positive-integer-or-empty-choice-type(this.value);

  final positive-integer-or-empty-choice-type value;
}
/// 
/// min inclusive: -180
typedef rotation-degrees = double;
enum semi-pitched {
  high,
  high,
  high,
  high,
  high,
  high,
}
typedef smufl-glyph-name = String;
/// 
/// pattern: (acc|medRenFla|medRenNatura|medRenShar|kievanAccidental)(\c+)
typedef smufl-accidental-glyph-name = SmuflGlyphName;
/// 
/// pattern: coda\c*
typedef smufl-coda-glyph-name = SmuflGlyphName;
/// 
/// pattern: lyrics\c+
typedef smufl-lyrics-glyph-name = SmuflGlyphName;
/// 
/// pattern: pict\c+
typedef smufl-pictogram-glyph-name = SmuflGlyphName;
/// 
/// pattern: segno\c*
typedef smufl-segno-glyph-name = SmuflGlyphName;
/// 
/// pattern: (wiggle\c+)|(guitar\c*VibratoStroke)
typedef smufl-wavy-line-glyph-name = SmuflGlyphName;
enum start-note {
  upper,
  upper,
  upper,
}
enum start-stop {
  start,
  start,
}
enum start-stop-continue {
  start,
  start,
  start,
}
enum start-stop-single {
  start,
  start,
  start,
}
typedef string-number = int;
enum symbol-size {
  full,
  full,
  full,
  full,
}
typedef tenths = double;
enum text-direction {
  ltr,
  ltr,
  ltr,
  ltr,
}
enum tied-type {
  start,
  start,
  start,
  start,
}
/// 
/// pattern: [1-9][0-9]*(, ?[1-9][0-9]*)*
typedef time-only = String;
enum top-bottom {
  top,
  top,
}
enum tremolo-type {
  start,
  start,
  start,
  start,
}
/// 
/// min inclusive: 2
typedef trill-beats = double;
enum trill-step {
  whole,
  whole,
  whole,
}
enum two-note-turn {
  whole,
  whole,
  whole,
}
enum up-down {
  up,
  up,
}
enum upright-inverted {
  upright,
  upright,
}
enum valign {
  top,
  top,
  top,
  top,
}
enum valign-image {
  top,
  top,
  top,
}
enum yes-no {
  yes,
  yes,
}
sealed class yes-no-number {
  const factory yes-no-number.yesNo(yes-no value) = yes-no-number_yes-no;
  const factory yes-no-number.xs:decimal(xs:decimal value) = yes-no-number_xs:decimal;
}

class yes-no-number_yes-no implements yes-no-number {
  const yes-no-number_yes-no(this.value);

  final yes-no value;
}
class yes-no-number_xs:decimal implements yes-no-number {
  const yes-no-number_xs:decimal(this.value);

  final xs:decimal value;
}
/// 
/// pattern: [^:Z]*
typedef yyyy-mm-dd = DateTime;
enum cancel-location {
  left,
  left,
  left,
}
enum clef-sign {
  G,
  G,
  G,
  G,
  G,
  G,
  G,
}
typedef fifths = int;
typedef mode = String;
enum show-frets {
  numbers,
  numbers,
}
typedef staff-line = int;
typedef staff-line-position = int;
typedef staff-number = int;
enum staff-type {
  ossia,
  ossia,
  ossia,
  ossia,
  ossia,
}
enum time-relation {
  parentheses,
  parentheses,
  parentheses,
  parentheses,
  parentheses,
  parentheses,
}
enum time-separator {
  none,
  none,
  none,
  none,
  none,
}
enum time-symbol {
  common,
  common,
  common,
  common,
  common,
  common,
}
enum backward-forward {
  backward,
  backward,
}
enum bar-style {
  regular,
  regular,
  regular,
  regular,
  regular,
  regular,
  regular,
  regular,
  regular,
  regular,
  regular,
}
/// 
/// pattern: ([ ]*)|([1-9][0-9]*(, ?[1-9][0-9]*)*)
typedef ending-number = String;
enum right-left-middle {
  right,
  right,
  right,
}
enum start-stop-discontinue {
  start,
  start,
  start,
}
enum winged {
  none,
  none,
  none,
  none,
  none,
}
/// 
/// min inclusive: 1
typedef accordion-middle = int;
enum beater-value {
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
  bow,
}
enum degree-symbol-value {
  major,
  major,
  major,
  major,
  major,
}
enum degree-type-value {
  add,
  add,
  add,
}
enum effect-value {
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
  anvil,
}
enum glass-value {
  glass harmonica,
  glass harmonica,
  glass harmonica,
}
enum harmony-arrangement {
  vertical,
  vertical,
  vertical,
}
enum harmony-type {
  explicit,
  explicit,
  explicit,
}
enum kind-value {
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
  major,
}
enum line-end {
  up,
  up,
  up,
  up,
  up,
}
enum measure-numbering-value {
  none,
  none,
  none,
}
enum membrane-value {
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
}
enum metal-value {
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
  agogo,
}
typedef milliseconds = int;
enum numeral-mode {
  major,
  major,
  major,
  major,
  major,
}
enum on-off {
  on,
  on,
}
enum pedal-type {
  start,
  start,
  start,
  start,
  start,
  start,
  start,
}
enum pitched-value {
  celesta,
  celesta,
  celesta,
  celesta,
  celesta,
  celesta,
  celesta,
  celesta,
  celesta,
  celesta,
  celesta,
}
enum principal-voice-symbol {
  Hauptstimme,
  Hauptstimme,
  Hauptstimme,
  Hauptstimme,
}
enum staff-divide-symbol {
  down,
  down,
  down,
}
enum start-stop-change-continue {
  start,
  start,
  start,
  start,
}
enum sync-type {
  none,
  none,
  none,
  none,
  none,
  none,
}
enum system-relation-number {
  only-top,
  only-top,
  only-top,
  only-top,
  only-top,
}
enum system-relation {
  only-top,
  only-top,
  only-top,
}
enum tip-direction {
  up,
  up,
  up,
  up,
  up,
  up,
  up,
  up,
}
enum stick-location {
  center,
  center,
  center,
  center,
}
enum stick-material {
  soft,
  soft,
  soft,
  soft,
  soft,
}
enum stick-type {
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
  bass drum,
}
enum up-down-stop-continue {
  up,
  up,
  up,
  up,
}
enum wedge-type {
  crescendo,
  crescendo,
  crescendo,
  crescendo,
}
enum wood-value {
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
  bamboo scraper,
}
typedef distance-type = String;
typedef glyph-type = String;
typedef line-width-type = String;
enum margin-type {
  odd,
  odd,
  odd,
}
typedef millimeters = double;
enum note-size-type {
  cue,
  cue,
  cue,
  cue,
}
enum accidental-value {
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
  sharp,
}
enum arrow-direction {
  left,
  left,
  left,
  left,
  left,
  left,
  left,
  left,
  left,
  left,
  left,
  left,
  left,
}
enum arrow-style {
  single,
  single,
  single,
  single,
  single,
  single,
  single,
}
enum beam-value {
  begin,
  begin,
  begin,
  begin,
  begin,
}
enum bend-shape {
  angled,
  angled,
}
enum breath-mark-value {
  ,
  ,
  ,
  ,
  ,
}
enum caesura-value {
  normal,
  normal,
  normal,
  normal,
  normal,
  normal,
}
enum circular-arrow {
  clockwise,
  clockwise,
}
enum fan {
  accel,
  accel,
  accel,
}
enum handbell-value {
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
  belltree,
}
enum harmon-closed-location {
  right,
  right,
  right,
  right,
}
enum harmon-closed-value {
  yes,
  yes,
  yes,
}
enum hole-closed-location {
  right,
  right,
  right,
  right,
}
enum hole-closed-value {
  yes,
  yes,
  yes,
}
enum note-type-value {
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
  1024th,
}
enum notehead-value {
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
  slash,
}
/// 
/// min inclusive: 0
typedef octave = int;
typedef semitones = double;
enum show-tuplet {
  actual,
  actual,
  actual,
}
enum stem-value {
  down,
  down,
  down,
  down,
}
enum step {
  A,
  A,
  A,
  A,
  A,
  A,
  A,
}
enum syllabic {
  single,
  single,
  single,
  single,
}
enum tap-hand {
  left,
  left,
}
/// 
/// min inclusive: 0
typedef tremolo-marks = int;
enum group-barline-value {
  yes,
  yes,
  yes,
}
enum group-symbol-value {
  none,
  none,
  none,
  none,
  none,
}
/// 
/// min length: 1
typedef measure-text = String;
enum swing-type-value {
  16th,
  16th,
}

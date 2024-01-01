// ignore: unused_import, always_use_package_imports
import 'barrel.g.dart';

/// The MusicXML format supports six levels of beaming, up to 1024th notes. Unlike the number-level type, the beam-level type identifies concurrent beams in a beam group. It does not distinguish overlapping beams such as grace notes within regular notes, or beams used in different voices.
/// 
/// min inclusive: 1
/// max inclusive: 8
typedef BeamLevel = int;

/// The color type indicates the color of an element. Color may be represented as hexadecimal RGB triples, as in HTML, or as hexadecimal ARGB tuples, with the A indicating alpha of transparency. An alpha value of 00 is totally transparent; FF is totally opaque. If RGB is used, the A value is assumed to be FF.
/// 
/// For instance, the RGB value "#800080" represents purple. An ARGB value of "#40800080" would be a transparent purple.
/// 
/// As in SVG 1.1, colors are defined in terms of the sRGB color space (IEC 61966).
/// 
/// pattern: #[\dA-F]{6}([\dA-F][\dA-F])?
typedef Color = String;

/// The comma-separated-text type is used to specify a comma-separated list of text elements, as is used by the font-family attribute.
/// 
/// pattern: [^,]+(, ?[^,]+)*
typedef CommaSeparatedText = String;

/// The divisions type is used to express values in terms of the musical divisions defined by the divisions element. It is preferred that these be integer values both for MIDI interoperability and to avoid roundoff errors.
typedef Divisions = double;

/// The font-family is a comma-separated list of font names. These can be specific font styles such as Maestro or Opus, or one of several generic font styles: music, engraved, handwritten, text, serif, sans-serif, handwritten, cursive, fantasy, and monospace. The music, engraved, and handwritten values refer to music fonts; the rest refer to text fonts. The fantasy style refers to decorative text such as found in older German-style printing.
typedef FontFamily = CommaSeparatedText;

/// The midi-16 type is used to express MIDI 1.0 values that range from 1 to 16.
/// 
/// min inclusive: 1
/// max inclusive: 16
typedef Midi16 = int;

/// The midi-128 type is used to express MIDI 1.0 values that range from 1 to 128.
/// 
/// min inclusive: 1
/// max inclusive: 128
typedef Midi128 = int;

/// The midi-16384 type is used to express MIDI 1.0 values that range from 1 to 16,384.
/// 
/// min inclusive: 1
/// max inclusive: 16384
typedef Midi16384 = int;

/// The non-negative-decimal type specifies a non-negative decimal value.
/// 
/// min inclusive: 0
typedef NonNegativeDecimal = double;

/// Slurs, tuplets, and many other features can be concurrent and overlap within a single musical part. The number-level entity distinguishes up to 16 concurrent objects of the same type when the objects overlap in MusicXML document order. Values greater than 6 are usually only needed for music with a large number of divisi staves in a single part, or if there are more than 6 cross-staff arpeggios in a single measure. When a number-level value is implied, the value is 1 by default.
/// 
/// When polyphonic parts are involved, the ordering within a MusicXML document can differ from musical score order. As an example, say we have a piano part in 4/4 where within a single measure, all the notes on the top staff are followed by all the notes on the bottom staff. In this example, each staff has a slur that starts on beat 2 and stops on beat 3, and there is a third slur that goes from beat 1 of one staff to beat 4 of the other staff.
/// 
/// In this situation, the two mid-measure slurs can use the same number because they do not overlap in MusicXML document order, even though they do overlap in musical score order. Within the MusicXML document, the top staff slur will both start and stop before the bottom staff slur starts and stops.
/// 
/// If the cross-staff slur starts in the top staff and stops in the bottom staff, it will need a separate number from the mid-measure slurs because it overlaps those slurs in MusicXML document order. However, if the cross-staff slur starts in the bottom staff and stops in the top staff, all three slurs can use the same number. None of them overlap within the MusicXML document, even though they all overlap each other in the musical score order. Within the MusicXML document, the start and stop of the top-staff slur will be followed by the stop and start of the cross-staff slur, followed by the start and stop of the bottom-staff slur.
/// 
/// As this example demonstrates, a reading program should be prepared to handle cases where the number-levels start and stop in an arbitrary order. Because the start and stop values refer to musical score order, a program may find the stopping point of an object earlier in the MusicXML document than it will find its starting point.
/// 
/// min inclusive: 1
/// max inclusive: 16
typedef NumberLevel = int;

/// The number-of-lines type is used to specify the number of lines in text decoration attributes.
/// 
/// min inclusive: 0
/// max inclusive: 3
typedef NumberOfLines = int;

/// The numeral-value type represents a Roman numeral or Nashville number value as a positive integer from 1 to 7.
/// 
/// min inclusive: 1
/// max inclusive: 7
typedef NumeralValue = int;

/// The percent type specifies a percentage from 0 to 100.
/// 
/// min inclusive: 0
/// max inclusive: 100
typedef Percent = double;

/// The positive-decimal type specifies a positive decimal value.
typedef PositiveDecimal = double;

/// The positive-divisions type restricts divisions values to positive numbers.
typedef PositiveDivisions = Divisions;

/// The rotation-degrees type specifies rotation, pan, and elevation values in degrees. Values range from -180 to 180.
/// 
/// min inclusive: -180
/// max inclusive: 180
typedef RotationDegrees = double;

/// The smufl-glyph-name type is used for attributes that reference a specific Standard Music Font Layout (SMuFL) character. The value is a SMuFL canonical glyph name, not a code point. For instance, the value for a standard piano pedal mark would be keyboardPedalPed, not U+E650.
typedef SmuflGlyphName = String;

/// The smufl-accidental-glyph-name type is used to reference a specific Standard Music Font Layout (SMuFL) accidental character. The value is a SMuFL canonical glyph name that starts with one of the strings used at the start of glyph names for SMuFL accidentals.
/// 
/// pattern: (acc|medRenFla|medRenNatura|medRenShar|kievanAccidental)(\c+)
typedef SmuflAccidentalGlyphName = SmuflGlyphName;

/// The smufl-coda-glyph-name type is used to reference a specific Standard Music Font Layout (SMuFL) coda character. The value is a SMuFL canonical glyph name that starts with coda.
/// 
/// pattern: coda\c*
typedef SmuflCodaGlyphName = SmuflGlyphName;

/// The smufl-lyrics-glyph-name type is used to reference a specific Standard Music Font Layout (SMuFL) lyrics elision character. The value is a SMuFL canonical glyph name that starts with lyrics.
/// 
/// pattern: lyrics\c+
typedef SmuflLyricsGlyphName = SmuflGlyphName;

/// The smufl-pictogram-glyph-name type is used to reference a specific Standard Music Font Layout (SMuFL) percussion pictogram character. The value is a SMuFL canonical glyph name that starts with pict.
/// 
/// pattern: pict\c+
typedef SmuflPictogramGlyphName = SmuflGlyphName;

/// The smufl-segno-glyph-name type is used to reference a specific Standard Music Font Layout (SMuFL) segno character. The value is a SMuFL canonical glyph name that starts with segno.
/// 
/// pattern: segno\c*
typedef SmuflSegnoGlyphName = SmuflGlyphName;

/// The smufl-wavy-line-glyph-name type is used to reference a specific Standard Music Font Layout (SMuFL) wavy line character. The value is a SMuFL canonical glyph name that either starts with wiggle, or begins with guitar and ends with VibratoStroke. This includes all the glyphs in the Multi-segment lines range, excluding the beam glyphs.
/// 
/// pattern: (wiggle\c+)|(guitar\c*VibratoStroke)
typedef SmuflWavyLineGlyphName = SmuflGlyphName;

/// The string-number type indicates a string number. Strings are numbered from high to low, with 1 being the highest pitched full-length string.
typedef StringNumber = int;

/// The tenths type is a number representing tenths of interline staff space (positive or negative). Both integer and decimal values are allowed, such as 5 for a half space and 2.5 for a quarter space. Interline space is measured from the middle of a staff line.
/// 
/// Distances in a MusicXML file are measured in tenths of staff space. Tenths are then scaled to millimeters within the scaling element, used in the defaults element at the start of a score. Individual staves can apply a scaling factor to adjust staff size. When a MusicXML element or attribute refers to tenths, it means the global tenths defined by the scaling element, not the local tenths as adjusted by the staff-size element.
typedef Tenths = double;

/// The time-only type is used to indicate that a particular playback- or listening-related element only applies particular times through a repeated section. The value is a comma-separated list of positive integers arranged in ascending order, indicating which times through the repeated section that the element applies.
/// 
/// pattern: [1-9][0-9]*(, ?[1-9][0-9]*)*
typedef TimeOnly = String;

/// The trill-beats type specifies the beats used in a trill-sound or bend-sound attribute group. It is a decimal value with a minimum value of 2.
/// 
/// min inclusive: 2
typedef TrillBeats = double;

/// Calendar dates are represented yyyy-mm-dd format, following ISO 8601. This is a W3C XML Schema date type, but without the optional timezone data.
/// 
/// pattern: [^:Z]*
typedef YyyyMmDd = DateTime;

/// The fifths type represents the number of flats or sharps in a traditional key signature. Negative numbers are used for flats and positive numbers for sharps, reflecting the key's placement within the circle of fifths (hence the type name).
typedef Fifths = int;

/// The mode type is used to specify major/minor and other mode distinctions. Valid mode values include major, minor, dorian, phrygian, lydian, mixolydian, aeolian, ionian, locrian, and none.
typedef Mode = String;

/// The staff-line type indicates the line on a given staff. Staff lines are numbered from bottom to top, with 1 being the bottom line on a staff.
typedef StaffLine = int;

/// The staff-line-position type indicates the line position on a given staff. Staff lines are numbered from bottom to top, with 1 being the bottom line on a staff. A staff-line-position value can extend beyond the range of the lines on the current staff.
typedef StaffLinePosition = int;

/// The staff-number type indicates staff numbers within a multi-staff part. Staves are numbered from top to bottom, with 1 being the top staff on a part.
typedef StaffNumber = int;

/// The ending-number type is used to specify either a comma-separated list of positive integers without leading zeros, or a string of zero or more spaces. It is used for the number attribute of the ending element. The zero or more spaces version is used when software knows that an ending is present, but cannot determine the type of the ending.
/// 
/// pattern: ([ ]*)|([1-9][0-9]*(, ?[1-9][0-9]*)*)
typedef EndingNumber = String;

/// The accordion-middle type may have values of 1, 2, or 3, corresponding to having 1 to 3 dots in the middle section of the accordion registration symbol. This type is not used if no dots are present.
/// 
/// min inclusive: 1
/// max inclusive: 3
typedef AccordionMiddle = int;

/// The milliseconds type represents an integral number of milliseconds.
typedef Milliseconds = int;

/// The system-relation type distinguishes elements that are associated with a system rather than the particular part where the element appears. A value of only-top indicates that the element should appear only on the top part of the current system. A value of also-top indicates that the element should appear on both the current part and the top part of the current system. If this value appears in a score, when parts are created the element should only appear once in this part, not twice. A value of none indicates that the element is associated only with the current part, not with the system.
typedef SystemRelation = SystemRelationNumber;

/// The distance-type defines what type of distance is being defined in a distance element. Values include beam and hyphen. This is left as a string so that other application-specific types can be defined, but it is made a separate type so that it can be redefined more strictly.
typedef DistanceType = String;

/// The glyph-type defines what type of glyph is being defined in a glyph element. Values include quarter-rest, g-clef-ottava-bassa, c-clef, f-clef, percussion-clef, octave-shift-up-8, octave-shift-down-8, octave-shift-continue-8, octave-shift-down-15, octave-shift-up-15, octave-shift-continue-15, octave-shift-down-22, octave-shift-up-22, and octave-shift-continue-22. This is left as a string so that other application-specific types can be defined, but it is made a separate type so that it can be redefined more strictly.
/// 
/// A quarter-rest type specifies the glyph to use when a note has a rest element and a type value of quarter. The c-clef, f-clef, and percussion-clef types specify the glyph to use when a clef sign element value is C, F, or percussion respectively. The g-clef-ottava-bassa type specifies the glyph to use when a clef sign element value is G and the clef-octave-change element value is -1. The octave-shift types specify the glyph to use when an octave-shift type attribute value is up, down, or continue and the octave-shift size attribute value is 8, 15, or 22.
typedef GlyphType = String;

/// The line-width-type defines what type of line is being defined in a line-width element. Values include beam, bracket, dashes, enclosure, ending, extend, heavy barline, leger, light barline, octave shift, pedal, slur middle, slur tip, staff, stem, tie middle, tie tip, tuplet bracket, and wedge. This is left as a string so that other application-specific types can be defined, but it is made a separate type so that it can be redefined more strictly.
typedef LineWidthType = String;

/// The millimeters type is a number representing millimeters. This is used in the scaling element to provide a default scaling from tenths to physical units.
typedef Millimeters = double;

/// Octaves are represented by the numbers 0 to 9, where 4 indicates the octave started by middle C.
/// 
/// min inclusive: 0
/// max inclusive: 9
typedef Octave = int;

/// The semitones type is a number representing semitones, used for chromatic alteration. A value of -1 corresponds to a flat and a value of 1 to a sharp. Decimal values like 0.5 (quarter tone sharp) are used for microtones.
typedef Semitones = double;

/// The number of tremolo marks is represented by a number from 0 to 8: the same as beam-level with 0 added.
/// 
/// min inclusive: 0
/// max inclusive: 8
typedef TremoloMarks = int;

/// The measure-text type is used for the text attribute of measure elements. It has at least one character. The implicit attribute of the measure element should be set to "yes" rather than setting the text attribute to an empty string.
typedef MeasureText = String;

/// The swing-type-value type specifies the note type, either eighth or 16th, to which the ratio defined in the swing element is applied.
typedef SwingTypeValue = NoteTypeValue;


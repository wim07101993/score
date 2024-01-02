// ignore_for_file: unused_import, always_use_package_imports, camel_case_types
import 'barrel.g.dart';

/// The bend-sound type is used for bend and slide elements, and is similar to the trill-sound attribute group. Here the beats element refers to the number of discrete elements (like MIDI pitch bends) used to represent a continuous bend or slide. The first-beat indicates the percentage of the duration for starting a bend; the last-beat the percentage for ending it. The default choices are:
/// 
/// 	accelerate = "no"
/// 	beats = "4"
/// 	first-beat = "25"
/// 	last-beat = "75"
abstract class BendSoundGroup {
  YesNo? get accelerate;
  TrillBeats? get beats;
  Percent? get firstBeat;
  Percent? get lastBeat;
}

/// The bezier attribute group is used to indicate the curvature of slurs and ties, representing the control points for a cubic bezier curve. For ties, the bezier attribute group is used with the tied element.
/// 
/// Normal slurs, S-shaped slurs, and ties need only two bezier points: one associated with the start of the slur or tie, the other with the stop. Complex slurs and slurs divided over system breaks can specify additional bezier data at slur elements with a continue type.
/// 
/// The bezier-x, bezier-y, and bezier-offset attributes describe the outgoing bezier point for slurs and ties with a start type, and the incoming bezier point for slurs and ties with types of stop or continue. The bezier-x2, bezier-y2, and bezier-offset2 attributes are only valid with slurs of type continue, and describe the outgoing bezier point.
/// 
/// The bezier-x, bezier-y, bezier-x2, and bezier-y2 attributes are specified in tenths, relative to any position settings associated with the slur or tied element. The bezier-offset and bezier-offset2 attributes are measured in terms of musical divisions, like the offset element. 
/// 
/// The bezier-offset and bezier-offset2 attributes are deprecated as of MusicXML 3.1. If both the bezier-x and bezier-offset attributes are present, the bezier-x attribute takes priority. Similarly, the bezier-x2 attribute takes priority over the bezier-offset2 attribute. The two types of bezier attributes are not additive.
abstract class BezierGroup {
  Tenths? get bezierX;
  Tenths? get bezierY;
  Tenths? get bezierX2;
  Tenths? get bezierY2;
  Divisions? get bezierOffset;
  Divisions? get bezierOffset2;
}

/// The color attribute group indicates the color of an element.
abstract class ColorGroup {
  Color? get color;
}

/// The dashed-formatting entity represents the length of dashes and spaces in a dashed line. Both the dash-length and space-length attributes are represented in tenths. These attributes are ignored if the corresponding line-type attribute is not dashed.
abstract class DashedFormattingGroup {
  Tenths? get dashLength;
  Tenths? get spaceLength;
}

/// The directive attribute changes the default-x position of a direction. It indicates that the left-hand side of the direction is aligned with the left-hand side of the time signature. If no time signature is present, it is aligned with the left-hand side of the first music notational element in the measure. If a default-x, justify, or halign attribute is present, it overrides the directive attribute.
abstract class DirectiveGroup {
  YesNo? get directive;
}

/// The document-attributes attribute group is used to specify the attributes for an entire MusicXML document. Currently this is used for the version attribute.
/// 
/// The version attribute was added in Version 1.1 for the score-partwise and score-timewise documents. It provides an easier way to get version information than through the MusicXML public ID. The default value is 1.0 to make it possible for programs that handle later versions to distinguish earlier version files reliably. Programs that write MusicXML 1.1 or later files should set this attribute.
abstract class DocumentAttributesGroup {
  String? get version;
}

/// The enclosure attribute group is used to specify the formatting of an enclosure around text or symbols.
abstract class EnclosureGroup {
  EnclosureShape? get enclosure;
}

/// The font attribute group gathers together attributes for determining the font within a credit or direction. They are based on the text styles for Cascading Style Sheets. The font-family is a comma-separated list of font names.The font-style can be normal or italic. The font-size can be one of the CSS sizes or a numeric point size. The font-weight can be normal or bold. The default is application-dependent, but is a text font vs. a music font.
abstract class FontGroup {
  FontFamily? get fontFamily;
  FontStyle? get fontStyle;
  FontSize? get fontSize;
  FontWeight? get fontWeight;
}

/// In cases where text extends over more than one line, horizontal alignment and justify values can be different. The most typical case is for credits, such as:
/// 
/// 	Words and music by
/// 	  Pat Songwriter
/// 
/// Typically this type of credit is aligned to the right, so that the position information refers to the right-most part of the text. But in this example, the text is center-justified, not right-justified.
/// 
/// The halign attribute is used in these situations. If it is not present, its value is the same as for the justify attribute. For elements where a justify attribute is not allowed, the default is implementation-dependent.
abstract class HalignGroup {
  LeftCenterRight? get halign;
}

/// The justify attribute is used to indicate left, center, or right justification. The default value varies for different elements. For elements where the justify attribute is present but the halign attribute is not, the justify attribute indicates horizontal alignment as well as justification.
abstract class JustifyGroup {
  LeftCenterRight? get justify;
}

/// The letter-spacing attribute specifies text tracking. Values are either "normal" or a number representing the number of ems to add between each letter. The number may be negative in order to subtract space. The default is normal, which allows flexibility of letter-spacing for purposes of text justification.
abstract class LetterSpacingGroup {
  NumberOrNormal? get letterSpacing;
}

/// The level-display attribute group specifies three common ways to indicate editorial indications: putting parentheses or square brackets around a symbol, or making the symbol a different size. If not specified, they are left to application defaults. It is used by the level and accidental elements.
abstract class LevelDisplayGroup {
  YesNo? get parentheses;
  YesNo? get bracket;
  SymbolSize? get size;
}

/// The line-height attribute specifies text leading. Values are either "normal" or a number representing the percentage of the current font height to use for leading. The default is "normal". The exact normal value is implementation-dependent, but values between 100 and 120 are recommended.
abstract class LineHeightGroup {
  NumberOrNormal? get lineHeight;
}

/// The line-length attribute distinguishes between different line lengths for doit, falloff, plop, and scoop articulations.
abstract class LineLengthGroup {
  LineLength? get lineLength;
}

/// The line-shape attribute distinguishes between straight and curved lines.
abstract class LineShapeGroup {
  LineShape? get lineShape;
}

/// The line-type attribute distinguishes between solid, dashed, dotted, and wavy lines.
abstract class LineTypeGroup {
  LineType? get lineType;
}

/// The optional-unique-id attribute group allows an element to optionally specify an ID that is unique to the entire document. This attribute group is not used for a required id attribute, or for an id attribute that specifies an id reference.
abstract class OptionalUniqueIdGroup {
  String? get id;
}

/// The orientation attribute indicates whether slurs and ties are overhand (tips down) or underhand (tips up). This is distinct from the placement attribute used by any notation type.
abstract class OrientationGroup {
  OverUnder? get orientation;
}

/// The placement attribute indicates whether something is above or below another element, such as a note or a notation.
abstract class PlacementGroup {
  AboveBelow? get placement;
}

/// For most elements, any program will compute a default x and y position. The position attributes let this be changed two ways.
/// 
/// The default-x and default-y attributes change the computation of the default position. For most elements, the origin is changed relative to the left-hand side of the note or the musical position within the bar (x) and the top line of the staff (y).
/// 
/// For the following elements, the default-x value changes the origin relative to the start of the current measure:
/// 
/// 	- note
/// 	- figured-bass
/// 	- harmony
/// 	- link
/// 	- directive
/// 	- measure-numbering
/// 	- all descendants of the part-list element
/// 	- all children of the direction-type element
/// 
/// This origin is from the start of the entire measure, at either the left barline or the start of the system.
/// 
/// When the default-x attribute is used within a child element of the part-name-display, part-abbreviation-display, group-name-display, or group-abbreviation-display elements, it changes the origin relative to the start of the first measure on the system. These values are used when the current measure or a succeeding measure starts a new system. The same change of origin is used for the group-symbol element.
/// 
/// For the note, figured-bass, and harmony elements, the default-x value is considered to have adjusted the musical position within the bar for its descendant elements.
/// 
/// Since the credit-words and credit-image elements are not related to a measure, in these cases the default-x and default-y attributes adjust the origin relative to the bottom left-hand corner of the specified page.
/// 
/// The relative-x and relative-y attributes change the position relative to the default position, either as computed by the individual program, or as overridden by the default-x and default-y attributes.
/// 
/// Positive x is right, negative x is left; positive y is up, negative y is down. All units are in tenths of interline space. For stems, positive relative-y lengthens a stem while negative relative-y shortens it.
/// 
/// The default-x and default-y position attributes provide higher-resolution positioning data than related features such as the placement attribute and the offset element. Applications reading a MusicXML file that can understand both features should generally rely on the default-x and default-y attributes for their greater accuracy. For the relative-x and relative-y attributes, the offset element, placement attribute, and directive attribute provide context for the relative position information, so the two features should be interpreted together.
/// 
/// As elsewhere in the MusicXML format, tenths are the global tenths defined by the scaling element, not the local tenths of a staff resized by the staff-size element.
abstract class PositionGroup {
  Tenths? get defaultX;
  Tenths? get defaultY;
  Tenths? get relativeX;
  Tenths? get relativeY;
}

/// The print-object attribute specifies whether or not to print an object (e.g. a note or a rest). It is yes by default.
abstract class PrintObjectGroup {
  YesNo? get printObject;
}

/// The print-spacing attribute controls whether or not spacing is left for an invisible note or object. It is used only if no note, dot, or lyric is being printed. The value is yes (leave spacing) by default.
abstract class PrintSpacingGroup {
  YesNo? get printSpacing;
}

/// The print-style attribute group collects the most popular combination of printing attributes: position, font, and color.
abstract class PrintStyleGroup implements PositionGroup, FontGroup, ColorGroup {
}

/// The print-style-align attribute group adds the halign and valign attributes to the position, font, and color attributes.
abstract class PrintStyleAlignGroup implements PrintStyleGroup, HalignGroup, ValignGroup {
}

/// The printout attribute group collects the different controls over printing an object (e.g. a note or rest) and its parts, including augmentation dots and lyrics. This is especially useful for notes that overlap in different voices, or for chord sheets that contain lyrics and chords but no melody.
/// 
/// By default, all these attributes are set to yes. If print-object is set to no, the print-dot and print-lyric attributes are interpreted to also be set to no if they are not present.
abstract class PrintoutGroup implements PrintObjectGroup, PrintSpacingGroup {
  YesNo? get printDot;
  YesNo? get printLyric;
}

/// The smufl attribute group is used to indicate a particular Standard Music Font Layout (SMuFL) character. Sometimes this is a formatting choice, and sometimes this is a refinement of the semantic meaning of an element.
abstract class SmuflGroup {
  SmuflGlyphName? get smufl;
}

/// The system-relation attribute group distinguishes elements that are associated with a system rather than the particular part where the element appears.
abstract class SystemRelationGroup {
  SystemRelation? get system;
}

/// The symbol-formatting attribute group collects the common formatting attributes for musical symbols. Default values may differ across the elements that use this group.
abstract class SymbolFormattingGroup implements JustifyGroup, PrintStyleAlignGroup, TextDecorationGroup, TextRotationGroup, LetterSpacingGroup, LineHeightGroup, TextDirectionGroup, EnclosureGroup {
}

/// The text-decoration attribute group is based on the similar feature in XHTML and CSS. It allows for text to be underlined, overlined, or struck-through. It extends the CSS version by allow double or triple lines instead of just being on or off.
abstract class TextDecorationGroup {
  NumberOfLines? get underline;
  NumberOfLines? get overline;
  NumberOfLines? get lineThrough;
}

/// The text-direction attribute is used to adjust and override the Unicode bidirectional text algorithm, similar to the Directionality data category in the W3C Internationalization Tag Set recommendation.
abstract class TextDirectionGroup {
  TextDirection? get dir;
}

/// The text-formatting attribute group collects the common formatting attributes for text elements. Default values may differ across the elements that use this group.
abstract class TextFormattingGroup implements JustifyGroup, PrintStyleAlignGroup, TextDecorationGroup, TextRotationGroup, LetterSpacingGroup, LineHeightGroup, TextDirectionGroup, EnclosureGroup {
  String? get lang;
  String? get space;
}

/// The rotation attribute is used to rotate text around the alignment point specified by the halign and valign attributes. Positive values are clockwise rotations, while negative values are counter-clockwise rotations.
abstract class TextRotationGroup {
  RotationDegrees? get rotation;
}

/// The trill-sound attribute group includes attributes used to guide the sound of trills, mordents, turns, shakes, and wavy lines. The default choices are:
/// 
/// 	start-note = "upper"
/// 	trill-step = "whole"
/// 	two-note-turn = "none"
/// 	accelerate = "no"
/// 	beats = "4".
/// 
/// Second-beat and last-beat are percentages for landing on the indicated beat, with defaults of 25 and 75 respectively.
/// 
/// For mordent and inverted-mordent elements, the defaults are different:
/// 
/// 	The default start-note is "main", not "upper".
/// 	The default for beats is "3", not "4".
/// 	The default for second-beat is "12", not "25".
/// 	The default for last-beat is "24", not "75".
abstract class TrillSoundGroup {
  StartNote? get startNote;
  TrillStep? get trillStep;
  TwoNoteTurn? get twoNoteTurn;
  YesNo? get accelerate;
  TrillBeats? get beats;
  Percent? get secondBeat;
  Percent? get lastBeat;
}

/// The valign attribute is used to indicate vertical alignment to the top, middle, bottom, or baseline of the text. Defaults are implementation-dependent.
abstract class ValignGroup {
  Valign? get valign;
}

/// The valign-image attribute is used to indicate vertical alignment for images and graphics, so it removes the baseline value. Defaults are implementation-dependent.
abstract class ValignImageGroup {
  ValignImage? get valign;
}

/// The x-position attribute group is used for elements like notes where specifying x position is common, but specifying y position is rare.
abstract class XPositionGroup {
  Tenths? get defaultX;
  Tenths? get defaultY;
  Tenths? get relativeX;
  Tenths? get relativeY;
}

/// The y-position attribute group is used for elements like stems where specifying y position is common, but specifying x position is rare.
abstract class YPositionGroup {
  Tenths? get defaultX;
  Tenths? get defaultY;
  Tenths? get relativeX;
  Tenths? get relativeY;
}

/// The image-attributes group is used to include graphical images in a score. The required source attribute is the URL for the image file. The required type attribute is the MIME type for the image file format. Typical choices include application/postscript, image/gif, image/jpeg, image/png, and image/tiff. The optional height and width attributes are used to size and scale an image. The image should be scaled independently in X and Y if both height and width are specified. If only one attribute is specified, the image should be scaled proportionally to fit in the specified dimension.
abstract class ImageAttributesGroup implements PositionGroup, HalignGroup, ValignImageGroup {
  String get source;
  String get type;
  Tenths? get height;
  Tenths? get width;
}

/// The print-attributes group is used by the print element. The new-system and new-page attributes indicate whether to force a system or page break, or to force the current music onto the same system or page as the preceding music. Normally this is the first music data within a measure. If used in multi-part music, they should be placed in the same positions within each part, or the results are undefined. The page-number attribute sets the number of a new page; it is ignored if new-page is not "yes". Version 2.0 adds a blank-page attribute. This is a positive integer value that specifies the number of blank pages to insert before the current measure. It is ignored if new-page is not "yes". These blank pages have no music, but may have text or images specified by the credit element. This is used to allow a combination of pages that are all text, or all text and images, together with pages of music.
/// 
/// The staff-spacing attribute specifies spacing between multiple staves in tenths of staff space. This is deprecated as of Version 1.1; the staff-layout element should be used instead. If both are present, the staff-layout values take priority.
abstract class PrintAttributesGroup {
  Tenths? get staffSpacing;
  YesNo? get newSystem;
  YesNo? get newPage;
  int? get blankPage;
  String? get pageNumber;
}

/// The element and position attributes are new as of Version 2.0. They allow for bookmarks and links to be positioned at higher resolution than the level of music-data elements. When no element and position attributes are present, the bookmark or link element refers to the next sibling element in the MusicXML file. The element attribute specifies an element type for a descendant of the next sibling element that is not a link or bookmark. The position attribute specifies the position of this descendant element, where the first position is 1. The position attribute is ignored if the element attribute is not present. For instance, an element value of "beam" and a position value of "2" defines the link or bookmark to refer to the second beam descendant of the next sibling element that is not a link or bookmark. This is equivalent to an XPath test of [.//beam[2]] done in the context of the sibling element.
abstract class ElementPositionGroup {
  String? get element;
  int? get position;
}

/// The link-attributes group includes all the simple XLink attributes supported in the MusicXML format. It is also used to connect a MusicXML score with MusicXML parts or a MusicXML opus.
abstract class LinkAttributesGroup {
  String get href;
  String? get type;
  String? get role;
  String? get title;
  String? get show;
  String? get actuate;
}

/// The group-name-text attribute group is used by the group-name and group-abbreviation elements. The print-style and justify attribute groups are deprecated in MusicXML 2.0 in favor of the new group-name-display and group-abbreviation-display elements.
abstract class GroupNameTextGroup implements PrintStyleGroup, JustifyGroup {
}

/// The measure-attributes group is used by the measure element. Measures have a required number attribute (going from partwise to timewise, measures are grouped via the number).
/// 
/// The implicit attribute is set to "yes" for measures where the measure number should never appear, such as pickup measures and the last half of mid-measure repeats. The value is "no" if not specified.
/// 
/// The non-controlling attribute is intended for use in multimetric music like the Don Giovanni minuet. If set to "yes", the left barline in this measure does not coincide with the left barline of measures in other parts. The value is "no" if not specified.
/// 
/// In partwise files, the number attribute should be the same for measures in different parts that share the same left barline. While the number attribute is often numeric, it does not have to be. Non-numeric values are typically used together with the implicit or non-controlling attributes being set to "yes". For a pickup measure, the number attribute is typically set to "0" and the implicit attribute is typically set to "yes". 
/// 
/// If measure numbers are not unique within a part, this can cause problems for conversions between partwise and timewise formats. The text attribute allows specification of displayed measure numbers that are different than what is used in the number attribute. This attribute is ignored for measures where the implicit attribute is set to "yes". Further details about measure numbering can be specified using the measure-numbering element.
/// 
/// Measure width is specified in tenths. These are the global tenths specified in the scaling element, not local tenths as modified by the staff-size element.	The width covers the entire measure from barline or system start to barline or system end.
abstract class MeasureAttributesGroup implements OptionalUniqueIdGroup {
  String get number;
  MeasureText? get text;
  YesNo? get implicit;
  YesNo? get nonControlling;
  Tenths? get width;
}

/// In either partwise or timewise format, the part element has an id attribute that is an IDREF back to a score-part in the part-list.
abstract class PartAttributesGroup {
  String get id;
}

/// The part-name-text attribute group is used by the part-name and part-abbreviation elements. The print-style and justify attribute groups are deprecated in MusicXML 2.0 in favor of the new part-name-display and part-abbreviation-display elements.
abstract class PartNameTextGroup implements PrintStyleGroup, PrintObjectGroup, JustifyGroup {
}

/// The editorial group specifies editorial information for a musical element.
abstract class EditorialGroup {
}

/// The editorial-voice group supports the common combination of editorial and voice information for a musical element.
abstract class EditorialVoiceGroup {
}

/// The editorial-voice-direction group supports the common combination of editorial and voice information for a direction element. It is separate from the editorial-voice element because extensions and restrictions might be different for directions than for the note and forward elements.
abstract class EditorialVoiceDirectionGroup {
}

/// The footnote element specifies editorial information that appears in footnotes in the printed score. It is defined within a group due to its multiple uses within the MusicXML schema.
abstract class FootnoteGroup {
}

/// The level element specifies editorial information for different MusicXML elements. It is defined within a group due to its multiple uses within the MusicXML schema.
abstract class LevelGroup {
}

/// The staff element is defined within a group due to its use by both notes and direction elements.
abstract class StaffGroup {
}

/// The tuning group contains the sequence of elements common to the staff-tuning and accord elements.
abstract class TuningGroup {
}

/// Virtual instrument data can be part of either the score-instrument element at the start of a part, or an instrument-change element within a part.
abstract class VirtualInstrumentDataGroup {
}

/// A voice is a sequence of musical events (e.g. notes, chords, rests) that proceeds linearly in time. The voice element is used to distinguish between multiple voices in individual parts. It is defined within a group due to its multiple uses within the MusicXML schema.
abstract class VoiceGroup {
}

/// Clefs are represented by a combination of sign, line, and clef-octave-change elements.
abstract class ClefGroup {
}

/// The non-traditional-key group represents a single alteration within a non-traditional key signature. A sequence of these groups makes up a non-traditional key signature
abstract class NonTraditionalKeyGroup {
}

/// The slash group combines elements used for more complete specification of the slash and beat-repeat measure-style elements. They have the same values as the type and dot elements, and define what the beat is for the display of repetition marks. If not present, the beat is based on the current time signature.
abstract class SlashGroup {
}

/// Time signatures are represented by the beats element for the numerator and the beat-type element for the denominator.
abstract class TimeSignatureGroup {
}

/// The traditional-key group represents a traditional key signature using the cycle of fifths.
abstract class TraditionalKeyGroup {
}

/// The transpose group represents what must be added to a written pitch to get a correct sounding pitch.
abstract class TransposeGroup {
}

/// The beat-unit group combines elements used repeatedly in the metronome element to specify a note within a metronome mark.
abstract class BeatUnitGroup {
}

/// A harmony element can contain many stacked chords (e.g. V of II). A sequence of harmony-chord groups is used for this type of secondary function, where V of II would be represented by a harmony-chord with a 5 numeral followed by a harmony-chord with a 2 numeral.
/// 
/// A root is a pitch name like C, D, E, while a numeral is a scale degree like 1, 2, 3. The root element is generally used with pop chord symbols, while the numeral element is generally used with classical functional harmony and Nashville numbers. It is an either/or choice to avoid data inconsistency. The function element, which represents Roman numerals with roman numeral text, has been deprecated as of MusicXML 4.0.
abstract class HarmonyChordGroup {
}

/// The all-margins group specifies both horizontal and vertical margins in tenths.
abstract class AllMarginsGroup {
}

/// The layout group specifies the sequence of page, system, and staff layout elements that is common to both the defaults and print elements.
abstract class LayoutGroup {
}

/// The left-right-margins group specifies horizontal margins in tenths.
abstract class LeftRightMarginsGroup {
}

/// The duration element is defined within a group due to its uses within the note, figured-bass, backup, and forward elements.
abstract class DurationGroup {
}

/// The display-step-octave group contains the sequence of elements used by both the rest and unpitched elements. This group is used to place rests and unpitched elements on the staff without implying that these elements have pitch. Positioning follows the current clef. If percussion clef is used, the display-step and display-octave elements are interpreted as if in treble clef, with a G in octave 4 on line 2.
abstract class DisplayStepOctaveGroup {
}

/// The full-note group is a sequence of the common note elements between cue/grace notes and regular (full) notes: pitch, chord, and rest information, but not duration (cue and grace notes do not have duration encoded). Unpitched elements are used for unpitched percussion, speaking voice, and other musical elements lacking determinate pitch.
abstract class FullNoteGroup {
}

/// The music-data group contains the basic musical data that is either associated with a part or a measure, depending on whether the partwise or timewise hierarchy is used.
abstract class MusicDataGroup {
}

/// The part-group element is defined within a group due to its multiple uses within the part-list element.
abstract class PartGroupGroup {
}

/// The score-header group contains basic score metadata about the work and movement, score-wide defaults for layout and fonts, credits that appear on the first or following pages, and the part list.
abstract class ScoreHeaderGroup {
}

/// The score-part element is defined within a group due to its multiple uses within the part-list element.
abstract class ScorePartGroup {
}

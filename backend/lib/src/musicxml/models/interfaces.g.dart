// ignore: unused_import, always_use_package_imports
import 'barrel.g.dart';

/// The bend-sound type is used for bend and slide elements, and is similar to the trill-sound attribute group. Here the beats element refers to the number of discrete elements (like MIDI pitch bends) used to represent a continuous bend or slide. The first-beat indicates the percentage of the duration for starting a bend; the last-beat the percentage for ending it. The default choices are:
/// 
/// 	accelerate = "no"
/// 	beats = "4"
/// 	first-beat = "25"
/// 	last-beat = "75"
abstract class BendSound {
  YesNo get accelerate;
  TrillBeats get beats;
  Percent get firstBeat;
  Percent get lastBeat;
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
abstract class Bezier {
  Tenths get bezierX;
  Tenths get bezierY;
  Tenths get bezierX2;
  Tenths get bezierY2;
  Divisions get bezierOffset;
  Divisions get bezierOffset2;
}

/// The color attribute group indicates the color of an element.
abstract class Color {
  Color get color;
}

/// The dashed-formatting entity represents the length of dashes and spaces in a dashed line. Both the dash-length and space-length attributes are represented in tenths. These attributes are ignored if the corresponding line-type attribute is not dashed.
abstract class DashedFormatting {
  Tenths get dashLength;
  Tenths get spaceLength;
}

/// The directive attribute changes the default-x position of a direction. It indicates that the left-hand side of the direction is aligned with the left-hand side of the time signature. If no time signature is present, it is aligned with the left-hand side of the first music notational element in the measure. If a default-x, justify, or halign attribute is present, it overrides the directive attribute.
abstract class Directive {
  YesNo get directive;
}

/// The document-attributes attribute group is used to specify the attributes for an entire MusicXML document. Currently this is used for the version attribute.
/// 
/// The version attribute was added in Version 1.1 for the score-partwise and score-timewise documents. It provides an easier way to get version information than through the MusicXML public ID. The default value is 1.0 to make it possible for programs that handle later versions to distinguish earlier version files reliably. Programs that write MusicXML 1.1 or later files should set this attribute.
abstract class DocumentAttributes {
  String get version;
}

/// The enclosure attribute group is used to specify the formatting of an enclosure around text or symbols.
abstract class Enclosure {
  EnclosureShape get enclosure;
}

/// The font attribute group gathers together attributes for determining the font within a credit or direction. They are based on the text styles for Cascading Style Sheets. The font-family is a comma-separated list of font names.The font-style can be normal or italic. The font-size can be one of the CSS sizes or a numeric point size. The font-weight can be normal or bold. The default is application-dependent, but is a text font vs. a music font.
abstract class Font {
  FontFamily get fontFamily;
  FontStyle get fontStyle;
  FontSize get fontSize;
  FontWeight get fontWeight;
}

/// In cases where text extends over more than one line, horizontal alignment and justify values can be different. The most typical case is for credits, such as:
/// 
/// 	Words and music by
/// 	  Pat Songwriter
/// 
/// Typically this type of credit is aligned to the right, so that the position information refers to the right-most part of the text. But in this example, the text is center-justified, not right-justified.
/// 
/// The halign attribute is used in these situations. If it is not present, its value is the same as for the justify attribute. For elements where a justify attribute is not allowed, the default is implementation-dependent.
abstract class Halign {
  LeftCenterRight get halign;
}

/// The justify attribute is used to indicate left, center, or right justification. The default value varies for different elements. For elements where the justify attribute is present but the halign attribute is not, the justify attribute indicates horizontal alignment as well as justification.
abstract class Justify {
  LeftCenterRight get justify;
}

/// The letter-spacing attribute specifies text tracking. Values are either "normal" or a number representing the number of ems to add between each letter. The number may be negative in order to subtract space. The default is normal, which allows flexibility of letter-spacing for purposes of text justification.
abstract class LetterSpacing {
  NumberOrNormal get letterSpacing;
}

/// The level-display attribute group specifies three common ways to indicate editorial indications: putting parentheses or square brackets around a symbol, or making the symbol a different size. If not specified, they are left to application defaults. It is used by the level and accidental elements.
abstract class LevelDisplay {
  YesNo get parentheses;
  YesNo get bracket;
  SymbolSize get size;
}

/// The line-height attribute specifies text leading. Values are either "normal" or a number representing the percentage of the current font height to use for leading. The default is "normal". The exact normal value is implementation-dependent, but values between 100 and 120 are recommended.
abstract class LineHeight {
  NumberOrNormal get lineHeight;
}

/// The line-length attribute distinguishes between different line lengths for doit, falloff, plop, and scoop articulations.
abstract class LineLength {
  LineLength get lineLength;
}

/// The line-shape attribute distinguishes between straight and curved lines.
abstract class LineShape {
  LineShape get lineShape;
}

/// The line-type attribute distinguishes between solid, dashed, dotted, and wavy lines.
abstract class LineType {
  LineType get lineType;
}

/// The optional-unique-id attribute group allows an element to optionally specify an ID that is unique to the entire document. This attribute group is not used for a required id attribute, or for an id attribute that specifies an id reference.
abstract class OptionalUniqueId {
  String get id;
}

/// The orientation attribute indicates whether slurs and ties are overhand (tips down) or underhand (tips up). This is distinct from the placement attribute used by any notation type.
abstract class Orientation {
  OverUnder get orientation;
}

/// The placement attribute indicates whether something is above or below another element, such as a note or a notation.
abstract class Placement {
  AboveBelow get placement;
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
abstract class Position {
  Tenths get defaultX;
  Tenths get defaultY;
  Tenths get relativeX;
  Tenths get relativeY;
}

/// The print-object attribute specifies whether or not to print an object (e.g. a note or a rest). It is yes by default.
abstract class PrintObject {
  YesNo get printObject;
}

/// The print-spacing attribute controls whether or not spacing is left for an invisible note or object. It is used only if no note, dot, or lyric is being printed. The value is yes (leave spacing) by default.
abstract class PrintSpacing {
  YesNo get printSpacing;
}

/// The print-style attribute group collects the most popular combination of printing attributes: position, font, and color.
abstract class PrintStyle {
}

/// The print-style-align attribute group adds the halign and valign attributes to the position, font, and color attributes.
abstract class PrintStyleAlign {
}

/// The printout attribute group collects the different controls over printing an object (e.g. a note or rest) and its parts, including augmentation dots and lyrics. This is especially useful for notes that overlap in different voices, or for chord sheets that contain lyrics and chords but no melody.
/// 
/// By default, all these attributes are set to yes. If print-object is set to no, the print-dot and print-lyric attributes are interpreted to also be set to no if they are not present.
abstract class Printout {
  YesNo get printDot;
  YesNo get printLyric;
}

/// The smufl attribute group is used to indicate a particular Standard Music Font Layout (SMuFL) character. Sometimes this is a formatting choice, and sometimes this is a refinement of the semantic meaning of an element.
abstract class Smufl {
  SmuflGlyphName get smufl;
}

/// The system-relation attribute group distinguishes elements that are associated with a system rather than the particular part where the element appears.
abstract class SystemRelation {
  SystemRelation get system;
}

/// The symbol-formatting attribute group collects the common formatting attributes for musical symbols. Default values may differ across the elements that use this group.
abstract class SymbolFormatting {
}

/// The text-decoration attribute group is based on the similar feature in XHTML and CSS. It allows for text to be underlined, overlined, or struck-through. It extends the CSS version by allow double or triple lines instead of just being on or off.
abstract class TextDecoration {
  NumberOfLines get underline;
  NumberOfLines get overline;
  NumberOfLines get lineThrough;
}

/// The text-direction attribute is used to adjust and override the Unicode bidirectional text algorithm, similar to the Directionality data category in the W3C Internationalization Tag Set recommendation.
abstract class TextDirection {
  TextDirection get dir;
}


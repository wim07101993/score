import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:songbird_musicxml/songbird_musicxml.dart';
import 'package:songbird_score/songbird_score.dart';

/// Writing a score back out the way it is being looked at.
///
/// A [ScoreView] is something that happens on the way to the screen: the
/// document a score is made of is what the editor uploaded and stays that way,
/// and hiding a part or transposing never touches it. That is the right thing
/// right up until somebody wants what is on their screen as a file — to print
/// it, to hand it to a player who reads a different key, to open it somewhere
/// else.
///
/// Nothing here writes to what it is given. The document is read into a score
/// of its own, changed and written out, so the file the app holds is the
/// uploaded one either way.

/// The score as the view has it: without the parts that are off screen, and in
/// the key it is being read in.
///
/// A view that changes nothing hands back exactly what it was given, so
/// downloading a score nobody has touched is still the editor's own file, byte
/// for byte. Anything else is written out of the model, which is a round trip
/// through it: everything MusicXML 4.0 can express survives, but the bytes are
/// the writer's rather than the original exporter's.
String musicXmlForView(String musicXml, ScoreView? view) {
  if (view == null || view.isPristine) {
    return musicXml;
  }

  final score = parseMusicXml(musicXml);
  applyView(score, view);
  return const MusicXmlWriter().write(score);
}

/// Puts [score] the way [view] has it: the hidden parts dropped and the whole
/// thing moved into the key it is being read in.
///
/// Written to be used on a score the caller owns — the one behind the sheet on
/// screen, or one just parsed for a download. It changes what it is given.
void applyView(Score score, ScoreView view) {
  final refs = readParts(score);

  // The key is read before any part is dropped, off the first part of the
  // whole score, because that is the one the sheet on screen reads it off: it
  // hides parts rather than dropping them. Read after, with the first part
  // hidden, the same number of semitones could be spelled as another key — F
  // flat major in the file where the screen shows E.
  final key = score.parts.isEmpty
      ? KeySignature.cMajor
      : score.parts.first.contextAtMeasure(0).keyFor(allStaves);

  // Parts are matched by the place they come in the score, the same way the
  // view names them, so a document with two parts that share an id still has
  // two parts that hide separately.
  final keep = <Part>[
    for (var index = 0; index < score.parts.length; index++)
      if (index >= refs.length || !view.isHidden(refs[index].id))
        score.parts[index],
  ];
  if (keep.isNotEmpty && keep.length != score.parts.length) {
    // Through withParts rather than by setting the list, because a part group
    // holds the places of its parts: left alone, a bracket would span parts
    // that have moved up, or places that are no longer there.
    final kept = score.withParts(keep);
    score
      ..parts = kept.parts
      ..partGroups = kept.partGroups;
  }

  if (view.transposition != 0) {
    ScoreEditor(score).execute(
      TransposeCommand(
        interval: Interval.chromaticFromKey(view.transposition, key),
      ),
    );
  }
}

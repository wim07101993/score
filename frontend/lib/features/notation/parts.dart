import 'package:songbird_musicxml/songbird_musicxml.dart';
import 'package:songbird_score/songbird_score.dart';

/// Reading a score, and naming its parts.
///
/// The engraving, the model and the file format all come from
/// `songbird_music_notation`; what is left here is the little the app adds on
/// top — a part needs a name to put in a control, and a score needs to be read
/// somewhere.

/// The score a MusicXML document describes.
///
/// Throws if the document cannot be read as one, which is what the upload path
/// leans on: a file that cannot be read is a file the band cannot play, and
/// finding that out after it is on the server is finding it out too late.
Score parseMusicXml(String musicXml) => const MusicXmlReader().read(musicXml);

/// The parts of a score, as the app names them.
///
/// A view names its parts by the id the document gives them, and falls back on
/// the place they come in the score when that id is no use: MusicXML part ids
/// are unique in a valid document, but a document that is being read is not
/// always valid, and a part with an empty id, or one another part already took,
/// is still a part. Taking one off the screen matches them up the same way, so
/// a score with two parts both called `P1` still has two parts that can be
/// hidden separately.
class ScorePartRef {
  const ScorePartRef(
    this.id,
    this.name,
  );

  final String id;

  /// What to call it in a control.
  final String name;

  @override
  String toString() => 'ScorePartRef($id, $name)';
}

/// The parts of a score, in the order it lists them.
List<ScorePartRef> readParts(Score score) {
  final parts = <ScorePartRef>[];
  final taken = <String>{};

  for (var index = 0; index < score.parts.length; index++) {
    final part = score.parts[index];

    var id = part.id.trim();
    if (id.isEmpty || taken.contains(id)) {
      // A document is free to call a real part `part-1` too, so the fallback
      // is walked on until it is one nothing has taken.
      var fallback = index;
      do {
        id = 'part-${fallback++}';
      } while (taken.contains(id));
    }
    taken.add(id);

    final name = part.name.trim();
    parts.add(ScorePartRef(id, name.isEmpty ? 'Part ${index + 1}' : name));
  }

  return parts;
}

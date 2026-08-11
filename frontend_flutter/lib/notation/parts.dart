import 'musicxml/model.dart';

/// The parts of a score, as the app names them.
///
/// A view names its parts by the place they come in the score rather than by
/// anything written in the document: MusicXML part ids are unique in a valid
/// document, but a document that is being read is not always valid, and a part
/// with no usable id is still a part. Taking one off the screen matches them up
/// the same way, so a score with two parts both called `P1` still has two parts
/// that can be hidden separately.
class ScorePartRef {
  const ScorePartRef(this.id, this.name);

  final String id;

  /// What to call it in a control.
  final String name;

  @override
  String toString() => 'ScorePartRef($id, $name)';
}

/// The parts of a score, in the order it lists them.
List<ScorePartRef> readParts(MusicXmlScore score) {
  final parts = <ScorePartRef>[];
  final taken = <String>{};

  for (var index = 0; index < score.parts.length; index++) {
    final part = score.parts[index];

    var id = part.id.trim();
    if (id.isEmpty || taken.contains(id)) {
      id = 'part-$index';
    }
    taken.add(id);

    final name = (part.name ?? '').trim();
    parts.add(ScorePartRef(id, name.isEmpty ? 'Part ${index + 1}' : name));
  }

  return parts;
}

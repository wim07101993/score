import 'package:score/features/scores/models.dart';
import 'package:songbird_musicxml/songbird_musicxml.dart' show MusicXmlDocument;

/// The details of a score read from its document on this device, the way the
/// server reads them when it is uploaded (`internal/score/add_or_update_score.go`):
/// so that a score that was just uploaded, or could not be, can be listed and
/// searched for before the server has said anything about it.
///
/// Null for a document that cannot be read, which is the server's to refuse.
/// [lastChangedAt] is this device's say until the server's copy is read back.
Score? readScoreDetails({
  required String scoreId,
  required String musicXml,
  required DateTime lastChangedAt,
}) {
  final score = switch (_parse(musicXml)) {
    final MusicXmlDocument document => document.partwise,
    null => null,
  };
  if (score == null) {
    return null;
  }

  // A creator without a type, or without a name, says nothing anybody could
  // look the score up by.
  final creators = (score.identification?.creator ?? const [])
      .where((creator) => creator.value.trim().isNotEmpty)
      .toList(growable: false);
  List<String> namesOf(String type) => creators
      .where((creator) => creator.type == type)
      .map((creator) => creator.value)
      .toList(growable: false);

  // The last language the document names, as the server keeps it.
  final language = score.defaults?.lyricLanguage.lastOrNull?.xmlLang ?? '';

  return Score(
    id: scoreId,
    lastChangedAt: lastChangedAt,
    work: Work(title: score.work?.workTitle, number: score.work?.workNumber),
    movement: Movement(
      title: score.movementTitle,
      number: score.movementNumber,
    ),
    creators: Creators(
      composers: namesOf('composer'),
      lyricists: namesOf('lyricist'),
    ),
    languages: language.isEmpty ? const [] : [language],
    instruments: score.partList.scorePartElements
        .expand((part) => part.scoreInstrumentElements)
        .map((instrument) => instrument.instrumentSound ?? '')
        .where((sound) => sound.isNotEmpty)
        .toList(growable: false),
  );
}

MusicXmlDocument? _parse(String musicXml) {
  try {
    return MusicXmlDocument.parse(musicXml);
  } catch (_) {
    return null;
  }
}

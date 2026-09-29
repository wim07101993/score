/// What the app that was there before this one kept in the browser: the
/// records as it stored them, and the score files by the id of their score.
///
/// Its records are written in the same shape this app writes its own, so they
/// are handed over as they are.
class LegacyData {
  const LegacyData({
    required this.scores,
    required this.sets,
    required this.musicXml,
  });

  final List<Map<String, Object?>> scores;
  final List<Map<String, Object?>> sets;
  final Map<String, String> musicXml;
}

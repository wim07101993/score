/// What the app that was there before this one kept in the browser: the
/// records as it stored them, the score files by the id of their score, and
/// what the device had been told to prefer.
///
/// Its records are written in the same shape this app writes its own, so they
/// are handed over as they are — save for the moments they were synced, which
/// the old app read off this device's clock where this one reads them off the
/// server's (see `LocalStore.bringOverLegacyData`).
class LegacyData {
  const LegacyData({
    this.scores = const [],
    this.sets = const [],
    this.collections = const [],
    this.musicXml = const {},
    this.themeMode,
    this.pageLookLight,
    this.pageLookDark,
    this.userInfo,
  });

  final List<Map<String, Object?>> scores;
  final List<Map<String, Object?>> sets;

  /// The collections, each with what it still owed the server — the pieces put
  /// in or taken out and the views written while there was no network — kept
  /// on the record itself, the way the old app kept them.
  final List<Map<String, Object?>> collections;

  final Map<String, String> musicXml;

  /// Which way round the app was told to be, as the old app wrote it: `light`
  /// or `dark`, and nothing at all for following the system — the same words
  /// this app uses.
  final String? themeMode;

  /// How the page was lit in a light and in a dark app, as the old app wrote
  /// it: the brightness and the warmth, as `<brightness>,<warmth>`, which is
  /// how this app writes it too.
  final String? pageLookLight;
  final String? pageLookDark;

  /// What the provider last said about the user, as the JSON the old app kept
  /// it in. Its fields are named as this app names them, so it is what a
  /// player on a stage with no network is recognised by until the provider can
  /// be asked again.
  final String? userInfo;

  /// Whether there is anything here at all.
  bool get isEmpty =>
      scores.isEmpty &&
      sets.isEmpty &&
      collections.isEmpty &&
      musicXml.isEmpty &&
      themeMode == null &&
      pageLookLight == null &&
      pageLookDark == null &&
      userInfo == null;
}

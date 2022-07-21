class ScoreFields {
  static const String id = 'id';
  static const String title = 'title';
  static const String subtitle = 'subtitle';
  static const String dedication = 'dedication';
  static const String createdAt = 'createdAt';
  static const String modifiedAt = 'modifiedAt';
  static const String composers = 'composers';
  static const String arrangements = 'arrangements';
  static const String tags = 'tags';
}

class ArrangementFields {
  static const String name = 'name';
  static const String arrangers = 'arrangers';
  static const String parts = 'parts';
}

class ArrangementPartFields {
  static const String links = 'links';
  static const String description = 'description';
  static const String targetInstrument = 'targetInstrument';
  static const String lyricists = 'lyricists';
}

class ScoreAccessHistoryItemFields {
  static const String userId = 'userId';
  static const String accessDate = 'accessDate';
  static const String scoreId = 'scoreId';
}

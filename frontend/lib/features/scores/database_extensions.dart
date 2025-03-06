class Queries {
  static const String _scoresCollection = 'scores';
  static const String _lastChangeTimestampColumn = 'lastChangeTimestamp';

  static const String getLastSyncTime = """
    SELECT $_lastChangeTimestampColumn 
    FROM $_scoresCollection
    ORDER BY $_lastChangeTimestampColumn
    LIMIT 1
  """;
}

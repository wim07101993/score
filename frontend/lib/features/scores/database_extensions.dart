import 'package:libsql_dart/libsql_dart.dart';

class Queries {
  static const String _scoresCollection = 'scores';
  static const String _lastChangedAtColumn = 'lastChangedAt';

  static const String getLastSyncTime = """
    SELECT $_lastChangedAtColumn 
    FROM $_scoresCollection
    ORDER BY $_lastChangedAtColumn
    LIMIT 1
  """;
}

extension ScoreMigrations on LibsqlClient {
  Future<void> applyScoreMigrations() {
    return _createScoresTable();
  }

  Future<void> _createScoresTable() {
    return execute("""
      CREATE TABLE IF NOT EXISTS scores
      (
          id                 TEXT PRIMARY KEY,
          work_title         TEXT,
          work_number        TEXT,
          movement_number    TEXT,
          movement_title     TEXT,
          creators_composers TEXT[],
          creators_lyricists TEXT[],
          languages          TEXT[],
          instruments        TEXT[],
          lastChangedAt      TIMESTAMP,
          tags               TEXT[]
      );
    """);
  }
}

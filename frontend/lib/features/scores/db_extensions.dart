import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/shared/libsql/converters.dart';
import 'package:score/shared/libsql/db_extensions.dart';

abstract class Tables {
  static const String scores = 'scores';
  static const String scoresFTS = 'scores_full_text_search';
}

abstract class Columns {
  static const String id = 'id';
  static const String workTitle = 'work_title';
  static const String workNumber = 'work_number';
  static const String movementTitle = 'movement_title';
  static const String movementNumber = 'movement_number';
  static const String creatorsComposers = 'creators_composers';
  static const String creatorsLyricists = 'creators_lyricists';
  static const String languages = 'languages';
  static const String instruments = 'instruments';
  static const String tags = 'tags';
  static const String lastChangedAt = 'lastChangedAt';
  static const String favouritedAt = 'favouritedAt';
}

extension ScoreDbExtensions on LibsqlClient {
  Future<DateTime> getLastSyncTime() async {
    final result = await query("""
      SELECT ${Columns.lastChangedAt} 
      FROM ${Tables.scores}
      ORDER BY ${Columns.lastChangedAt}
      LIMIT 1
    """);
    if (result.isEmpty) {
      return DateTime(0);
    }
    return DateTime(0);
  }

  Future<Score?> getScore(String scoreId) {
    return query(
      'SELECT * '
      'FROM ${Tables.scores} '
      'WHERE ${Columns.id} = ?',
      positional: [scoreId],
    ).then(
      (results) => results.isEmpty ? null : Score.fromDatabase(results[0]),
    );
  }

  Future<void> insertScore(Score score) {
    final columns = [
      Columns.id,
      Columns.workTitle,
      Columns.workNumber,
      Columns.movementTitle,
      Columns.movementNumber,
      Columns.creatorsComposers,
      Columns.creatorsLyricists,
      Columns.languages,
      Columns.instruments,
      Columns.lastChangedAt,
      Columns.tags,
    ];
    final lastChangedAt = dateTimeToSqlDateTime(score.lastChangedAt);
    return execute(
      'INSERT INTO ${Tables.scores} (${columns.join(', ')}) '
      "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, '$lastChangedAt', ?)",
      positional: [
        score.id,
        score.work?.title,
        score.work?.number,
        score.movement?.title,
        score.movement?.number,
        score.creators.composers,
        score.creators.lyricists,
        score.languages,
        score.instruments,
        score.tags,
      ],
    );
  }

  Future<void> updateScore(Score score) async {
    await execute(
      """
      UPDATE ${Tables.scores} SET
  			${Columns.workTitle} = ?, 
  			${Columns.workNumber} = ?,
  			${Columns.movementTitle} = ?,
  			${Columns.movementNumber} = ?,
  			${Columns.creatorsComposers} = ?,
  			${Columns.creatorsLyricists} = ?,
  			${Columns.languages} = ?,
  		  ${Columns.instruments} = ?,
  			${Columns.lastChangedAt} = '${dateTimeToSqlDateTime(score.lastChangedAt)}',
  		  ${Columns.tags} = ? 
      WHERE ${Columns.id} = ?
    """,
      positional: [
        score.work?.title,
        score.work?.number,
        score.movement?.title,
        score.movement?.number,
        score.creators.composers,
        score.creators.lyricists,
        score.languages,
        score.instruments,
        score.tags,
        score.id,
      ],
    );
  }

  Stream<Score> search(String query) {
    return stream(
      'SELECT * '
      'FROM ${Tables.scoresFTS} '
      'WHERE ${Tables.scoresFTS} MATCH ? '
      'ORDER BY RANK',
      positional: [query],
    ).map((result) => Score.fromDatabase(result));
  }

  Future<void> applyScoreMigrations() {
    return _createScoresTable()
        .then((_) => _createFullTextSearchVirtualTable());
  }

  Future<void> _createScoresTable() {
    return execute("""
      CREATE TABLE IF NOT EXISTS ${Tables.scores}
      (
          ${Columns.id}                TEXT PRIMARY KEY NOT NULL,
          ${Columns.workTitle}         TEXT,
          ${Columns.workNumber}        TEXT,
          ${Columns.movementTitle}     TEXT,
          ${Columns.movementNumber}    TEXT,
          ${Columns.creatorsComposers} TEXT[],
          ${Columns.creatorsLyricists} TEXT[],
          ${Columns.languages}         TEXT[],
          ${Columns.instruments}       TEXT[],
          ${Columns.lastChangedAt}     TIMESTAMP NOT NULL,
          ${Columns.tags}              TEXT[],
          ${Columns.favouritedAt}      TIMESTAMP
      );
    """);
  }

  Future<void> _createFullTextSearchVirtualTable() {
    return execute(
      """
      CREATE VIRTUAL TABLE IF NOT EXISTS ${Tables.scoresFTS} 
      USING fts5(
          ${Columns.id},
          ${Columns.workTitle},
          ${Columns.workNumber},
          ${Columns.movementTitle},
          ${Columns.movementNumber},
          ${Columns.creatorsComposers},
          ${Columns.creatorsLyricists},
          ${Columns.languages},
          ${Columns.instruments},
          ${Columns.lastChangedAt},
          ${Columns.tags},
          ${Columns.favouritedAt}
      );
      """,
    );
  }
}

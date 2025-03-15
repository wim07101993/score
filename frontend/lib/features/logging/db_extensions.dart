import 'dart:async';

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/shared/libsql/converters.dart';
import 'package:score/shared/libsql/db_extensions.dart';

abstract class Tables {
  static const String logs = 'logs';
}

abstract class Columns {
  static const String levelName = 'level_name';
  static const String levelValue = 'level_value';
  static const String message = 'message';
  static const String loggerName = 'loggerName';
  static const String time = 'time';
  static const String sequenceNumber = 'sequenceNumber';
  static const String stackTrace = 'stackTrace';
  static const String error = 'error';
  static const String object = 'object';
}

extension LogsDbExtensions on LibsqlClient {
  Future<void> insertLogRecord(LogRecord logRecord) {
    final columns = [
      Columns.sequenceNumber,
      Columns.time,
      Columns.levelValue,
      Columns.levelName,
      Columns.loggerName,
      Columns.message,
      Columns.object,
      Columns.error,
      Columns.stackTrace,
    ];
    final time = dateTimeToSqlDateTime(logRecord.time);
    return execute(
      'INSERT INTO ${Tables.logs} (${columns.join(', ')}) '
      "Values (?, '$time', ?, ?, ?, ?, ?, ?, ?)",
      positional: [
        logRecord.sequenceNumber,
        logRecord.level.value,
        logRecord.level.name,
        logRecord.loggerName,
        logRecord.message,
        logRecord.object,
        logRecord.error,
        logRecord.stackTrace,
      ],
    );
  }

  Stream<LogRecord> getLogs() {
    return stream('SELECT * FROM ${Tables.logs} ORDER BY ${Columns.time} DESC')
        .map((result) => _LogRecord.fromDatabase(result));
  }

  Future<void> applyLogMigrations() {
    return _createLogsTable();
  }

  Future<void> _createLogsTable() {
    return execute("""
      CREATE TABLE IF NOT EXISTS ${Tables.logs}
      (
        ${Columns.sequenceNumber} INTEGER NOT NULL,
        ${Columns.time}           TIMESTAMP PRIMARY KEY NOT NULL,
        ${Columns.levelName}      TEXT NOT NULL,
        ${Columns.levelValue}     INTEGER NOT NULL,
        ${Columns.loggerName}     TEXT NOT NULL,
        ${Columns.message}        TEXT NOT NULL,
        ${Columns.object}         TEXT,
        ${Columns.error}          TEXT,
        ${Columns.stackTrace}     TEXT
      );
    """);
  }
}

class _LogRecord implements LogRecord {
  const _LogRecord({
    required this.level,
    required this.loggerName,
    required this.message,
    required this.time,
    required this.sequenceNumber,
    required this.stackTrace,
    required this.error,
    required this.object,
  });

  factory _LogRecord.fromDatabase(Map<String, dynamic> map) {
    final stackTrace = map[Columns.stackTrace] as String?;
    return _LogRecord(
      level: Level(
        map[Columns.levelName] as String,
        map[Columns.levelValue] as int,
      ),
      loggerName: map[Columns.loggerName] as String,
      message: map[Columns.message] as String,
      time: sqlStringToDateTime(map[Columns.time] as String),
      sequenceNumber: map[Columns.sequenceNumber] as int,
      stackTrace: stackTrace == null ? null : StackTrace.fromString(stackTrace),
      error: map[Columns.stackTrace] as String?,
      object: map[Columns.object] as String?,
    );
  }

  @override
  final Level level;
  @override
  final String loggerName;
  @override
  final String message;
  @override
  final DateTime time;
  @override
  final int sequenceNumber;
  @override
  final StackTrace? stackTrace;
  @override
  final Object? error;
  @override
  final Object? object;
  @override
  Zone? get zone => null;
}

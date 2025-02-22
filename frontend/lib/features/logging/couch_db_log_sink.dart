import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';

class CouchDbLogSink extends LogSink {
  CouchDbLogSink({
    required this.database,
  });

  final Future<Collection> database;

  @override
  Future<void> write(LogRecord logRecord) {
    return database
        .then((db) => db.saveDocument(convertLogRecordToDoc(logRecord)));
  }
}

abstract class LogRecordPropertyNames {
  static const String level = 'level';
  static const String levelName = 'name';
  static const String levelValue = 'value';
  static const String message = 'message';
  static const String loggerName = 'loggerName';
  static const String time = 'time';
  static const String sequenceNumber = 'sequenceNumber';
  static const String stackTrace = 'stackTrace';
  static const String error = 'error';
  static const String object = 'object';
}

MutableDocument convertLogRecordToDoc(LogRecord logRecord) {
  return MutableDocument()
    ..setDictionary(
      MutableDictionary({
        LogRecordPropertyNames.levelName: logRecord.level.name,
        LogRecordPropertyNames.levelValue: logRecord.level.value,
      }),
      key: LogRecordPropertyNames.level,
    )
    ..setString(logRecord.message, key: LogRecordPropertyNames.message)
    ..setString(logRecord.loggerName, key: LogRecordPropertyNames.loggerName)
    ..setDate(logRecord.time, key: LogRecordPropertyNames.time)
    ..setInteger(
      logRecord.sequenceNumber,
      key: LogRecordPropertyNames.sequenceNumber,
    )
    ..setString(
      logRecord.stackTrace?.toString(),
      key: LogRecordPropertyNames.stackTrace,
    )
    ..setString(logRecord.error?.toString(), key: LogRecordPropertyNames.error)
    ..setString(
      logRecord.object?.toString(),
      key: LogRecordPropertyNames.object,
    );
}

LogRecord convertDocToLogRecord(Document doc) {
  final level = doc.dictionary(LogRecordPropertyNames.level);
  final stackTrace = doc.string(LogRecordPropertyNames.stackTrace);
  return _LogRecord(
    level: level == null
        ? Level.ALL
        : Level(
            level.string(LogRecordPropertyNames.levelName) ?? '',
            level.integer(LogRecordPropertyNames.levelValue),
          ),
    loggerName: doc.string(LogRecordPropertyNames.loggerName) ?? '',
    message: doc.string(LogRecordPropertyNames.message) ?? '',
    time: doc.date(LogRecordPropertyNames.time) ?? DateTime.now().toUtc(),
    sequenceNumber: doc.integer(LogRecordPropertyNames.sequenceNumber),
    stackTrace: stackTrace == null ? null : StackTrace.fromString(stackTrace),
    error: doc.string(LogRecordPropertyNames.error),
    object: doc.string(LogRecordPropertyNames.object),
  );
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

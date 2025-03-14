import 'dart:async';

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/features/logging/db_extensions.dart';

class DbLogSink extends LogSink {
  DbLogSink({
    required this.database,
  });

  final Future<LibsqlClient> database;

  @override
  Future<void> write(LogRecord logRecord) {
    return database.then((db) => db.insertLogRecord(logRecord));
  }
}

import 'dart:async';

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:hive_ce/hive.dart';

class DbLogSink extends LogSink {
  DbLogSink({
    required this.database,
  });

  final Future<LazyBox<LogRecord>> database;

  @override
  Future<void> write(LogRecord logRecord) {
    return database.then((db) => db.add(logRecord));
  }
}

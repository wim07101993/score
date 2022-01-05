import 'dart:async';

import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:hive/hive.dart';
import 'package:score/data/guid_generator.dart';

class HiveLogSink extends LogSink {
  HiveLogSink({
    required this.guidGenerator,
    required this.hive,
  }) {
    final oldestThreshold = DateTime.now().subtract(const Duration(days: 14));
    _box().then((box) => box.keys
        .cast<String>()
        .where((key) => DateTime.fromMicrosecondsSinceEpoch(int.parse(key))
            .isBefore(oldestThreshold))
        .forEach(box.delete));
  }

  final GuidGenerator guidGenerator;
  final HiveInterface hive;

  Future<Box<LogRecord>> _box() {
    return hive.openBox<LogRecord>('logs');
  }

  @override
  Future<void> write(LogRecord logRecord) {
    return _box().then((box) {
      return box.put(
          logRecord.time.microsecondsSinceEpoch.toString(), logRecord);
    });
  }

  Future<Iterable<LogRecord>> getAll() {
    return _box().then((box) => box.values);
  }
}

import 'dart:async';

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:score/shared/hive_type_ids.dart';

class HiveLogSink extends LogSink {
  HiveLogSink({
    required this.box,
  });

  final Future<Box<LogRecord>> box;

  @override
  Future<void> write(LogRecord logRecord) {
    return box.then((box) async {
      if (!box.isOpen) {
        return;
      }
      await box.add(logRecord);
    });
  }
}

class LogRecordAdapter implements TypeAdapter<LogRecord> {
  const LogRecordAdapter();

  @override
  int get typeId => HiveTypeIds.logRecord;

  @override
  LogRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _HiveLogRecord(
      level: fields[0] as Level,
      message: fields[1] as String,
      object: fields[2] as Object?,
      loggerName: fields[3] as String,
      time: fields[4] as DateTime,
      sequenceNumber: (fields[5] as num).toInt(),
      error: fields[6] as Object?,
      stackTrace: fields[7] as StackTrace?,
    );
  }

  @override
  void write(BinaryWriter writer, LogRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.level)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.object)
      ..writeByte(3)
      ..write(obj.loggerName)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.sequenceNumber)
      ..writeByte(6)
      ..write(obj.error)
      ..writeByte(7)
      ..write(obj.stackTrace);
  }
}

class LogLevelAdapter implements TypeAdapter<Level> {
  const LogLevelAdapter();

  @override
  int get typeId => HiveTypeIds.logLevel;

  @override
  Level read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Level(
      fields[0] as String,
      (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Level obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.value);
  }
}

class _HiveLogRecord implements LogRecord {
  _HiveLogRecord({
    required this.level,
    required this.message,
    required this.object,
    required this.loggerName,
    required this.time,
    required this.sequenceNumber,
    required this.error,
    required this.stackTrace,
  });

  @override
  final Level level;
  @override
  final String message;
  @override
  final Object? object;
  @override
  final String loggerName;
  @override
  final DateTime time;
  @override
  final int sequenceNumber;
  @override
  final Object? error;
  @override
  final StackTrace? stackTrace;
  @override
  Zone? get zone => null;
}

import 'dart:async';

import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:hive/hive.dart';

class _LogRecord implements LogRecord {
  _LogRecord({
    required this.error,
    required this.level,
    required this.loggerName,
    required this.message,
    required this.object,
    required this.sequenceNumber,
    required this.stackTrace,
    required this.time,
  });

  @override
  final Object? error;

  @override
  final Level level;

  @override
  final String loggerName;

  @override
  final String message;

  @override
  final Object? object;

  @override
  final int sequenceNumber;

  @override
  final StackTrace? stackTrace;

  @override
  final DateTime time;

  @override
  Zone? get zone => null;
}

class LogRecordAdapter extends TypeAdapter<LogRecord> {
  @override
  final int typeId = 0;

  @override
  LogRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _LogRecord(
      level: fields[0] as Level,
      message: fields[1] as String,
      object: fields[2] as String?,
      loggerName: fields[3] as String,
      time: DateTime.parse(fields[4] as String),
      sequenceNumber: fields[5] as int,
      error: fields[6] as String?,
      stackTrace:
          fields[7] == null ? null : StackTrace.fromString(fields[8] as String),
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
      ..write(obj.object?.toString())
      ..writeByte(3)
      ..write(obj.loggerName)
      ..writeByte(4)
      ..write(obj.time.toIso8601String())
      ..writeByte(5)
      ..write(obj.sequenceNumber)
      ..writeByte(6)
      ..write(obj.error?.toString())
      ..writeByte(7)
      ..write(obj.stackTrace?.toString());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LogRecordAdapter &&
            runtimeType == other.runtimeType &&
            typeId == other.typeId;
  }
}

class LevelAdapter extends TypeAdapter<Level> {
  @override
  final int typeId = 1;

  @override
  Level read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Level(
      fields[0] as String,
      fields[1] as int,
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LevelAdapter &&
            runtimeType == other.runtimeType &&
            typeId == other.typeId;
  }
}

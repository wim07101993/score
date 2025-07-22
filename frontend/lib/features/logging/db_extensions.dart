import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:hive_ce/hive.dart';
import 'package:score/shared/hive/type_ids.dart';

class LogRecordAdapter implements TypeAdapter<LogRecord> {
  const LogRecordAdapter();

  @override
  int get typeId => TypeIds.logRecord;

  @override
  LogRecord read(BinaryReader reader) {
    // THE ORDER OF THESE READS IS IMPORTANT!!
    return LogRecord(
      reader.readType(),
      reader.readString(),
      reader.readString(),
      reader.read(),
      reader.readType(),
      null,
      reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, LogRecord logRecord) {
    // THE ORDER OF THESE WRITES IS IMPORTANT!!
    writer
      ..write(logRecord.level)
      ..writeString(logRecord.message)
      ..writeString(logRecord.loggerName);

    final error = logRecord.error;
    if (error == null || TypeIds.all.containsKey(error.runtimeType)) {
      writer.write(error);
    } else {
      writer.write(error.toString());
    }

    writer.write(logRecord.stackTrace);

    final object = logRecord.object;
    if (object == null || TypeIds.all.containsKey(object.runtimeType)) {
      writer.write(object);
    } else {
      writer.write(object.toString());
    }
  }
}

class LogLevelAdapter implements TypeAdapter<Level> {
  const LogLevelAdapter();

  @override
  int get typeId => TypeIds.logLevel;

  @override
  Level read(BinaryReader reader) {
    return Level(reader.readString(), reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Level obj) {
    writer
      ..writeString(obj.name)
      ..writeInt(obj.value);
  }
}

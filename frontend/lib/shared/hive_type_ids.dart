import 'package:hive_ce_flutter/adapters.dart';

class HiveTypeIds {
  static const int logRecord = 0;
  static const int logLevel = 1;
  static const int stackTrace = 2;
  static const int behaviourLogObject = 3;
}

class StackTraceAdapter implements TypeAdapter<StackTrace> {
  const StackTraceAdapter();

  @override
  int get typeId => HiveTypeIds.stackTrace;

  @override
  StackTrace read(BinaryReader reader) {
    return StackTrace.fromString(reader.readString());
  }

  @override
  void write(BinaryWriter writer, StackTrace obj) {
    writer.writeString(obj.toString());
  }
}

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:hive_ce/hive.dart';

class TypeIds {
  static const int stackTrace = 1;
  static const int logRecord = 2;
  static const int logLevel = 3;
  static const int score = 4;
  static const int movement = 5;
  static const int work = 6;
  static const int creators = 7;

  static const all = {
    StackTrace: TypeIds.stackTrace,
    LogRecord: TypeIds.logRecord,
    Level: TypeIds.logLevel,
  };
}

extension BinaryReaderExtensions on BinaryReader {
  T readType<T>() {
    return read() as T;
  }
}

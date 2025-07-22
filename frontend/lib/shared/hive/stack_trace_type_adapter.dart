import 'package:hive_ce/hive.dart';
import 'package:score/shared/hive/type_ids.dart';

class NullableStackTraceTypeAdapter implements TypeAdapter<StackTrace?> {
  const NullableStackTraceTypeAdapter();

  @override
  StackTrace? read(BinaryReader reader) {
    final val = reader.read();
    return val == null ? null : StackTrace.fromString(val as String);
  }

  @override
  int get typeId => TypeIds.stackTrace;

  @override
  void write(BinaryWriter writer, StackTrace? obj) {
    writer.write(obj?.toString());
  }
}

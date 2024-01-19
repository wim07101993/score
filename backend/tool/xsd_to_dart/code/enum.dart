import 'dart:io';

import 'code.dart';

void writeEnum(
  IOSink sink, {
  required String name,
  required List<String> values,
  required List<String> docs,
}) {
  writeDocs(sink, docs: docs);
  sink.writeln('enum $name {');
  for (final enumeration in values) {
    sink.writeln('  $enumeration,');
  }
  sink.writeln('}');
}

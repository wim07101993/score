import 'dart:io';

import 'code.dart';

void writeEnum(
  IOSink sink, {
  required String name,
  required List<(List<String> docs, String name)> values,
  required List<String> docs,
}) {
  writeDocs(sink, docs: docs);
  sink.writeln('enum $name {');
  for (final (docs, enumeration) in values) {
    writeDocs(sink, docs: docs, indent: 1);
    sink.writeln('  $enumeration,');
  }
  sink.writeln('}');
}

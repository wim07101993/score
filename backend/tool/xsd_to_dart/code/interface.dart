import 'dart:io';

import 'code.dart';

void writeInterface(
  IOSink sink, {
  required String name,
  required List<(String type, String name)> properties,
  required List<String> interfaces,
  required List<String> docs,
}) {
  writeDocs(sink, docs: docs);

  sink.write('abstract class $name ');
  if (interfaces.isNotEmpty) {
    sink.write('implements ${interfaces.join(', ')} ');
  }

  sink.writeln('{');

  for (final (type, name) in properties) {
    sink.writeln('  $type get $name;');
  }

  sink.writeln('}');
}

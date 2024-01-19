import 'dart:io';

import 'code.dart';

void writeInterface(
  IOSink sink, {
  required String name,
  List<(String type, String name)> properties = const [],
  List<String> interfaces = const [],
  List<String> docs = const [],
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

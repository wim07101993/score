import 'dart:io';

import 'code.dart';

void writeAlias(
  IOSink sink, {
  required String name,
  required String baseType,
  required List<String> restrictions,
  required List<String> docs,
}) {
  writeDocs(
    sink,
    docs: [
      ...docs,
      if (restrictions.isNotEmpty) '',
      ...restrictions,
    ],
  );
  sink.writeln('typedef $name = $baseType;');
}

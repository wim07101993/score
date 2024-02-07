import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

part 'union.dart';

void writeDocs(
  IOSink sink, {
  required List<String> docs,
  int indent = 0,
}) {
  if (docs.isEmpty) {
    return;
  }
  for (final doc in docs.expand((doc) => doc.split('\n'))) {
    sink.write(''.padLeft(indent * 2));
    sink.write('/// ');
    sink.writeln(doc);
  }
}

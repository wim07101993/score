import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

part 'union.dart';

mixin Code {
  List<String> get docs;

  void writeTo(IOSink sink);

  void writeDocs(IOSink sink, {int indent = 0}) {
    if (docs.isEmpty) {
      return;
    }
    for (final doc in docs.expand((doc) => doc.split('\n'))) {
      sink.write(''.padLeft(indent));
      sink.write('/// ');
      sink.writeln(doc);
    }
  }
}

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

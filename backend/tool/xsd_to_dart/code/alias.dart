import 'dart:io';

import 'documentation.dart';

class TypeDef {
  const TypeDef({
    required this.name,
    required this.baseType,
    this.docs,
  });

  final String name;
  final String baseType;
  final Docs? docs;

  void writeTo(IOSink sink) {
    docs?.writeTo(sink);
    sink.writeln('typedef $name = $baseType;');
  }
}

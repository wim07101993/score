import 'dart:io';

import 'dart_type.dart';
import 'documentation.dart';

class Property {
  const Property({
    required this.name,
    required this.type,
    this.docs,
    this.isNullable = false,
    this.isOverride = false,
  });

  final String name;
  final DartType type;
  final Docs? docs;
  final bool isNullable;
  final bool isOverride;

  void writeTo(IOSink sink) {
    docs?.writeTo(sink);

    if (isOverride) {
      sink.writeln('@override');
    }

    sink.write('final $type');
    if (isNullable) {
      sink.write('?');
    }
    sink.writeln(' $name;');
  }
}

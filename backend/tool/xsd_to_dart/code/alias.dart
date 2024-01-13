import 'dart:io';

import 'code.dart';

void writeAlias(
  IOSink sink, {
  required String name,
  required String baseType,
  required String? minLength,
  required String? minExclusive,
  required String? minInclusive,
  required String? maxInclusive,
  required String? pattern,
  required List<String> docs,
}) {
  writeDocs(
    sink,
    docs: [
      ...docs,
      if (minLength != null ||
          minExclusive != null ||
          minInclusive != null ||
          maxInclusive != null ||
          pattern != null)
        '',
      if (minLength != null) 'min length: $minLength',
      if (minExclusive != null) 'min exclusive: $minExclusive',
      if (minInclusive != null) 'min inclusive: $minInclusive',
      if (maxInclusive != null) 'max inclusive: $maxInclusive',
      if (pattern != null) 'pattern: $pattern',
    ],
  );
  sink.writeln('typedef $name = $baseType;');
}

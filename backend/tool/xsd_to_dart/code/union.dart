part of 'code.dart';

void writeUnion(
  IOSink sink, {
  required String name,
  required List<String> types,
  required List<String> docs,
}) {
  writeDocs(sink, docs: docs);

  sink.writeln('sealed class $name {');
  for (final type in types) {
    final camelCase = Casing.camelCase(type);
    final subType = _subType(name, type);
    sink.writeln('  const factory $name.$camelCase($type value) = $subType;');
  }

  sink
    ..writeln('}')
    ..writeln();

  for (final type in types) {
    final subType = _subType(name, type);
    sink
      ..writeln('class $subType implements $name {')
      ..writeln('  const $subType(this.value);')
      ..writeln()
      ..writeln('  final $type value;')
      ..writeln('}');
  }
}

String _subType(String name, String type) => '${name}_$type';

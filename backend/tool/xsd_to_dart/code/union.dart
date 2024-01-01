part of 'code.dart';

class Union extends Type {
  const Union({
    required super.docs,
    required this.name,
    required this.types,
  });

  final String name;
  final List<String> types;

  @override
  void writeTo(IOSink sink) {
    print('writing enum $name');
    writeDocs(sink);

    sink.writeln('sealed class $name {');
    for (final type in types) {
      final camelCase = Casing.camelCase(type);
      final subType = this.subType(type);
      sink.writeln('  const factory $name.$camelCase($type value) = $subType;');
    }

    sink
      ..writeln('}')
      ..writeln();

    for (final type in types) {
      final subType = this.subType(type);
      sink
        ..writeln('class $subType implements $name {')
        ..writeln('  const $subType(this.value);')
        ..writeln()
        ..writeln('  final $type value;')
        ..writeln('}')
        ..writeln();
    }
  }

  String subType(String type) => '${name}_$type';
}

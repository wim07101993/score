part of 'code.dart';

class Union extends Type {
  const Union({
    required super.docs,
    required super.name,
    required this.types,
  });

  final List<String> types;

  @override
  void writeTo(IOSink sink) {
    // ignore: avoid_print
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
        ..writeln('}');
    }
  }

  String subType(String type) => '${name}_$type';
}

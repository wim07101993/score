part of 'code.dart';

class Enum extends Type {
  const Enum({
    required this.name,
    required this.values,
    required super.docs,
  });

  final String name;
  final List<String> values;

  @override
  void writeTo(IOSink sink) {
    print('writing enum $name');
    writeDocs(sink);

    sink.writeln('enum $name {');
    for (final value in values) {
      sink.writeln('  $value,');
    }

    sink
      ..writeln('}')
      ..writeln();
  }
}

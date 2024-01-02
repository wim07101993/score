part of 'code.dart';

class Enum extends Type {
  const Enum({
    required super.name,
    required super.docs,
    required this.values,
  });

  final List<String> values;

  @override
  void writeTo(IOSink sink) {
    // ignore: avoid_print
    print('writing enum $name');
    writeDocs(sink);

    sink.writeln('enum $name {');
    for (final value in values) {
      sink.writeln('  $value,');
    }
    sink.writeln('}');
  }
}

import '../code_sink.dart';
import 'code.dart';

class Enum extends Code {
  const Enum({
    required this.name,
    required this.values,
    required super.docs,
  });

  final String name;
  final List<String> values;

  @override
  void writeTo(CodeSink sink) {
    print('writing enum $name');
    writeDocs(sink.enumSink);

    sink.enumSink
      ..write('enum ')
      ..write(name)
      ..writeln(' {');

    for (final value in values) {
      sink.enumSink
        ..write('  ')
        ..write(value)
        ..writeln(',');
    }

    sink.enumSink
      ..writeln('}')
      ..writeln();
  }
}

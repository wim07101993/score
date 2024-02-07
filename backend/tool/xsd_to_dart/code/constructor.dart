import 'dart:io';

import 'documentation.dart';
import 'parameter.dart';

class Constructor {
  const Constructor({
    required this.type,
    this.name,
    this.isConst = false,
    this.parameters = const [],
    this.docs,
  });

  final String type;
  final String? name;
  final bool isConst;
  final List<ConstructorParameter> parameters;
  final Docs? docs;

  void writeTo(IOSink sink) {
    docs?.writeTo(sink);

    sink.write('  $type');
    final name = this.name;
    if (name != null) {
      sink.write('.$name');
    }
    sink.write('(');

    if (parameters.isNotEmpty) {
      sink.writeln('{');
      for (final parameter in parameters) {
        parameter.writeTo(sink);
      }
      sink.write('}');
    }
    sink.writeln(');');
  }
}

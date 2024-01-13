import 'dart:io';

import '../xsd/types/typed_mixin.dart';
import 'code.dart';

void writeClass(
  IOSink sink, {
  required String name,
  required List<
          (
            String type,
            String name,
            bool override,
            bool useSuperContructor,
          )>
      properties,
  required String? baseType,
  required List<String> interfaces,
  required List<String> mixins,
  required List<String> docs,
}) {
  writeDocs(sink, docs: docs);

  sink.write('class $name ');
  if (baseType is ComplexType) {
    sink.write('extends $baseType ');
  }
  if (mixins.isNotEmpty) {
    sink.write('with ${mixins.join(', ')} ');
  }

  sink
    ..writeln('{')
    ..writeln(' const $name({');

  for (final (_, name, _, useSuperConstructor) in properties) {
    if (useSuperConstructor) {
      sink.writeln('    required super.$name,');
    } else {
      sink.writeln('    required this.$name,');
    }
  }

  sink
    ..writeln('  });')
    ..writeln();

  for (final (type, name, override, _) in properties) {
    if (override) {
      sink.writeln('  @override');
    }
    sink.writeln('  final $type $name;');
  }

  sink.writeln('}');
}

import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

import '../xsd_to_dart.dart';

part 'alias.dart';
part 'class.dart';
part 'enum.dart';
part 'interface.dart';
part 'property.dart';
part 'union.dart';

abstract class Code {
  const Code({
    required this.docs,
  });

  final List<String> docs;

  void writeTo(IOSink sink);

  void writeDocs(IOSink sink, {int indent = 0}) {
    if (docs.isEmpty) {
      return;
    }
    for (final doc in docs.expand((doc) => doc.split('\n'))) {
      sink.write(''.padLeft(indent));
      sink.write('/// ');
      sink.writeln(doc);
    }
  }
}

sealed class Type extends Code {
  const Type({
    required super.docs,
    required this.name,
  });

  final String name;
}

sealed class ComplexType extends Type {
  ComplexType({
    required super.name,
    required super.docs,
    required this.properties,
    required List<String> interfaces,
  }) : interfaces = interfaces
            .map((interface) => '${interface}Group')
            .toList(growable: false);

  final List<Property> properties;
  final List<String> interfaces;

  Iterable<Property> getAllProperties() sync* {
    yield* properties;
    yield* interfaces
        .map(resolveInterface)
        .expand((type) => type.getAllProperties());
  }
}

class NativeType extends Type {
  NativeType._(String name) : super(docs: const [], name: name);

  factory NativeType.int() => NativeType._('int');
  factory NativeType.double() => NativeType._('double');
  factory NativeType.string() => NativeType._('String');

  @override
  void writeTo(IOSink sink) {
    throw Exception('native types should not be defined again');
  }
}

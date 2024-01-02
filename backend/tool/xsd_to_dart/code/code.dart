import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

part 'alias.dart';
part 'class.dart';
part 'enum.dart';
part 'interface.dart';
part 'native_type.dart';
part 'property.dart';
part 'union.dart';

mixin Code {
  List<String> get docs;

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

sealed class Type with Code {
  const Type({
    required this.docs,
    required this.name,
  });

  final String name;
  @override
  final List<String> docs;
}

sealed class ComplexType extends Type {
  ComplexType({
    required super.name,
    required super.docs,
    required this.properties,
    required this.interfaces,
  });

  final List<Property> properties;
  final List<Interface> interfaces;

  Iterable<Property> getAllProperties() sync* {
    yield* properties;
    yield* interfaces.expand((type) => type.getAllProperties());
  }
}

part of 'code.dart';

class Class extends ComplexType {
  Class({
    required super.name,
    required super.docs,
    required super.properties,
    required super.interfaces,
    required this.baseType,
  });

  final Type? baseType;

  @override
  void writeTo(IOSink sink) {
    // ignore: avoid_print
    print('writing class $name');
    writeDocs(sink);

    final allProperties = getAllProperties();
    final baseType = this.baseType;

    sink.write('class $name ');
    if (baseType is ComplexType) {
      sink.write('extends ${baseType.name} ');
    }
    if (interfaces.isNotEmpty) {
      sink.write('implements ${interfaces.map((i) => i.name).join(', ')} ');
    }

    sink
      ..writeln('{')
      ..writeln(' const $name({');

    if (baseType is ComplexType) {
      for (final param in baseType
          .getAllProperties()
          .map((p) => p.toConstructorParameter(isSuper: true))) {
        param.writeTo(sink);
      }
    } else if (baseType != null) {
      ConstructorParameter(
        docs: baseType.docs,
        name: 'value',
        isSuper: false,
      ).writeTo(sink);
    }

    for (final param in allProperties.map((p) => p.toConstructorParameter())) {
      param.writeTo(sink);
    }

    sink
      ..writeln('  });')
      ..writeln();

    if (baseType != null && baseType is! ComplexType) {
      PropertyImplementation(
        name: 'value',
        docs: baseType.docs,
        type: baseType,
        isNullable: false,
        isOverridden: false,
      ).writeTo(sink);
    }

    for (final property
        in allProperties.map((p) => p.toPropertyImplementation())) {
      property.writeTo(sink);
    }

    sink.writeln('}');
  }
}

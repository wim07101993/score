part of 'dart_type.dart';

class Class implements DartType {
  const Class({
    required this.name,
    this.base,
    this.docs,
    this.constructors = const [],
    this.properties = const [],
  });

  @override
  final String name;
  final DartType? base;
  final Docs? docs;
  final List<Constructor> constructors;
  final List<Property> properties;

  void writeTo(IOSink sink) {
    docs?.writeTo(sink);

    sink.write('class $name ');
    final base = this.base;
    if (base != null) {
      sink.write('extends $base ');
    }

    sink.writeln('{');

    for (final constructor in constructors) {
      constructor.writeTo(sink);
    }

    if (properties.isNotEmpty && constructors.isNotEmpty) {
      sink.writeln();
    }

    for (final property in properties) {
      property.writeTo(sink);
    }

    sink.writeln('}');
  }
}

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
  required List<String> docs,
}) {
  Class(
    name: name,
    docs: Docs(lines: docs),
    base: baseType == null ? null : resolveDartType(baseType),
    properties: properties
        .map(
          (property) => Property(
            type: resolveDartType(property.$1),
            name: property.$2,
            isOverride: property.$3,
          ),
        )
        .toList(growable: false),
    constructors: [
      Constructor(
        type: name,
        isConst: true,
        parameters: properties
            .map(
              (property) => ConstructorParameter(
                name: property.$2,
                isRequired: true,
                comesFromSuper: property.$4,
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}

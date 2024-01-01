part of 'code.dart';

class Interface extends Type {
  Interface({
    required this.name,
    required super.docs,
    required this.properties,
  });

  final String name;
  final List<Property> properties;

  @override
  void writeTo(IOSink sink) {
    writeDocs(sink);

    sink.writeln('abstract class $name {');
    for (final property in properties) {
      property.writeTo(sink);
    }
    sink
      ..writeln('}')
      ..writeln();
  }
}

class Property extends Code {
  const Property({
    required super.docs,
    required this.name,
    required this.type,
  });

  final String name;
  final String type;

  @override
  void writeTo(IOSink sink) {
    writeDocs(sink, indent: 2);

    sink.writeln('  $type get $name;');
  }
}

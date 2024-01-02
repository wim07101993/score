part of 'code.dart';

sealed class Property with Code {
  const Property({
    required this.docs,
    required this.name,
    required this.type,
    required this.isNullable,
  });

  final String name;
  @override
  final List<String> docs;
  final Type type;
  final bool isNullable;

  ConstructorParameter toConstructorParameter({bool isSuper = false}) {
    return ConstructorParameter(docs: docs, name: name, isSuper: isSuper);
  }

  AbstractProperty toAbstractProperty() {
    return AbstractProperty(
      docs: docs,
      name: name,
      type: type,
      isNullable: isNullable,
    );
  }

  PropertyImplementation toPropertyImplementation() {
    return PropertyImplementation(
      docs: docs,
      name: name,
      type: type,
      isNullable: isNullable,
      isOverridden: true,
    );
  }
}

class AbstractProperty extends Property {
  const AbstractProperty({
    required super.docs,
    required super.name,
    required super.type,
    required super.isNullable,
  });

  @override
  void writeTo(IOSink sink) {
    writeDocs(sink, indent: 2);

    if (isNullable) {
      sink.writeln('  ${type.name}? get $name;');
    } else {
      sink.writeln('  ${type.name} get $name;');
    }
  }

  @override
  AbstractProperty toAbstractProperty() => this;
}

class PropertyImplementation extends Property {
  const PropertyImplementation({
    required super.docs,
    required super.name,
    required super.type,
    required super.isNullable,
    required this.isOverridden,
  });

  final bool isOverridden;

  @override
  void writeTo(IOSink sink) {
    writeDocs(sink);

    if (isOverridden) {
      sink.writeln('  @override');
    }

    if (isNullable) {
      sink.writeln('  final ${type.name}? $name;');
    } else {
      sink.writeln('  final ${type.name} $name;');
    }
  }

  @override
  PropertyImplementation toPropertyImplementation() => this;
}

class ConstructorParameter with Code {
  ConstructorParameter({
    required this.docs,
    required this.name,
    required this.isSuper,
  });

  final String name;
  final bool isSuper;
  @override
  final List<String> docs;

  @override
  void writeTo(IOSink sink) {
    if (isSuper) {
      sink.writeln('    required super.$name,');
    } else {
      sink.writeln('    required this.$name,');
    }
  }
}

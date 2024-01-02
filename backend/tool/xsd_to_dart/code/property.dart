part of 'code.dart';

sealed class Property extends Code {
  const Property({
    required super.docs,
    required this.name,
    required this.type,
    required this.isNullable,
  });

  final String name;
  final String type;
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
      sink.writeln('  $type? get $name;');
    } else {
      sink.writeln('  $type get $name;');
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
      sink.writeln('  final $type? $name;');
    } else {
      sink.writeln('  final $type $name;');
    }
  }

  @override
  PropertyImplementation toPropertyImplementation() => this;
}

class ConstructorParameter extends Code {
  ConstructorParameter({
    required super.docs,
    required this.name,
    required this.isSuper,
  });

  final String name;
  final bool isSuper;

  @override
  void writeTo(IOSink sink) {
    if (isSuper) {
      sink.writeln('    required super.$name,');
    } else {
      sink.writeln('    required this.$name,');
    }
  }
}

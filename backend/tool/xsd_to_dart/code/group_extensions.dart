import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

import '../xsd/attributes/attribute.dart';
import '../xsd/attributes/attribute_group.dart';
import '../xsd/elements/element.dart';
import '../xsd/elements/group.dart';
import 'interface.dart';
import 'string_extensions.dart';
import 'xsd_node_extension.dart';

extension AttributeGroupExtensions on AttributeGroup {
  String get dartTypeName => 'I${Casing.pascalCase(name)}';

  Iterable<Attribute> get allAttributes sync* {
    yield* attributes;
    yield* attributeGroups.expand((group) => group.allAttributes);
  }

  void writeAsCode(IOSink sink) {
    writeInterface(
      sink,
      name: dartTypeName,
      properties: attributes
          .map(
            (attribute) => (
              attribute.type.name.toDartTypeName(),
              attribute.name.toPropertyName()
            ),
          )
          .toList(growable: false),
      interfaces: attributeGroups
          .map((group) => group.dartTypeName)
          .toList(growable: false),
      docs: docs,
    );
  }
}

extension GroupExtensions on Group {
  String get dartTypeName => 'I${Casing.pascalCase(name)}';

  Iterable<Element> get allElements sync* {
    yield* elements;
    yield* groups.expand((group) => group.allElements);
  }

  void writeAsCode(IOSink sink) {
    writeInterface(
      sink,
      name: dartTypeName,
      properties: elements
          .map(
            (element) => (
              'types.${element.type.name.toDartTypeName()}',
              element.name.toPropertyName()
            ),
          )
          .toList(growable: false),
      interfaces:
          groups.map((group) => group.dartTypeName).toList(growable: false),
      docs: docs,
    );
  }
}

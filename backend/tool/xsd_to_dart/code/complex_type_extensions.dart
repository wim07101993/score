import 'dart:io';

import '../xsd/attributes/attribute.dart';
import '../xsd/elements/element.dart';
import '../xsd/types/typed_mixin.dart';
import 'attribute_group_extensions.dart';
import 'class.dart';
import 'group_extensions.dart';
import 'string_extensions.dart';
import 'xsd_node_extension.dart';

extension ComplexTypeExtensions on ComplexType {
  Iterable<Attribute> get allAttributes sync* {
    yield* attributes;
    yield* attributeGroups.expand((group) => group.allAttributes);
  }

  Iterable<Element> get allElements sync* {
    yield* elements;
    yield* groups.expand((group) => group.allElements);
  }

  void writeAsCode(IOSink sink) {
    writeClass(
      sink,
      name: name.toDartTypeName(),
      properties: [
        ...allAttributes.map(
          (attribute) => (
            attribute.type.name.toDartTypeName(),
            attribute.name.toPropertyName(),
            true,
            false,
          ),
        ),
        ...allElements.map(
          (element) => (
            element.type.name.toDartTypeName(),
            element.name.toPropertyName(),
            true,
            false,
          ),
        ),
      ],
      baseType: simpleContent?.extension?.base.name,
      interfaces: [
        ...attributeGroups.map((group) => group.name.toDartTypeName()),
        ...groups.map((group) => group.name.toDartTypeName()),
      ],
      mixins: const [],
      docs: docs,
    );
  }
}

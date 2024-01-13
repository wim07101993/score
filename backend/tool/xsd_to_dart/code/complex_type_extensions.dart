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
      name: name,
      properties: [
        ...allAttributes.map(
          (attribute) => (
            attribute.type.name.toDartTypeName(),
            attribute.name,
            true,
            false,
          ),
        ),
        ...allElements.map(
          (element) => (
            element.type.name.toDartTypeName(),
            element.name,
            true,
            false,
          ),
        ),
      ],
      baseType: simpleContent?.extension?.base.name,
      interfaces: [
        ...attributeGroups.map((group) => group.name),
        ...groups.map((group) => group.name),
      ],
      mixins: const [],
      docs: docs,
    );
  }
}

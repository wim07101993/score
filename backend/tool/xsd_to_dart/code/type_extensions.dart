import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

import '../xsd/attributes/attribute.dart';
import '../xsd/elements/element.dart';
import '../xsd/restriction/restriction.dart';
import '../xsd/types/typed_mixin.dart';
import 'alias.dart';
import 'class.dart';
import 'code.dart';
import 'enum.dart';
import 'group_extensions.dart';
import 'string_extensions.dart';
import 'xsd_node_extension.dart';

extension XsdTypeExtensions on XsdType {
  String get dartTypeName {
    final type = this;
    if (type is TypeReference) {
      return switch (type.name) {
        'string' => 'GuitarString',
        'xs:integer' => 'int',
        'xs:positiveInteger' => 'int',
        'xs:nonNegativeInteger' => 'int',
        'xs:decimal' => 'double',
        'xs:token' => 'String',
        'xs:string' => 'String',
        'xs:NMTOKEN' => 'String',
        'xs:ID' => 'String',
        'xs:anyURI' => 'String',
        'xs:IDREF' => 'String',
        'xml:lang' => 'String',
        'xml:space' => 'String',
        'xlink:href' => 'String',
        'xlink:type' => 'String',
        'xlink:role' => 'String',
        'xlink:title' => 'String',
        'xlink:show' => 'String',
        'xlink:actuate' => 'String',
        'xs:date' => 'DateTime',
        String() => Casing.pascalCase(type.name),
      };
    }
    return Casing.pascalCase(name);
  }
}

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
      name: name.toDartClassName(),
      properties: [
        ...allAttributes.map(
          (attribute) => (
            attribute.type.dartTypeName,
            attribute.name.toPropertyName(),
            true,
            false,
          ),
        ),
        ...allElements.map(
          (element) => (
            element.type.dartTypeName,
            element.name.toPropertyName(),
            true,
            false,
          ),
        ),
      ],
      baseType: simpleContent?.extension?.base.name,
      interfaces: [
        ...attributeGroups.map((group) => group.dartTypeName),
        ...groups.map((group) => group.dartTypeName),
      ],
      docs: docs,
    );
  }
}

extension SimpleTypeExtensions on SimpleType {
  void writeAsCode(IOSink sink) {
    final value = this.value;
    switch (value) {
      case SimpleTypeValueRestriction():
        final restrictions = value.restriction.values;
        if (restrictions.firstOrNull is EnumeratedRestrictionValue) {
          writeEnum(
            sink,
            docs: docs,
            name: name.toDartClassName(),
            values: restrictions.enumerations
                .map((e) => (e.docs, e.value.toEnumValueName()))
                .toList(growable: false),
          );
        } else {
          writeAlias(
            sink,
            name: name.toDartClassName(),
            baseType: value.restriction.base.dartTypeName,
            minLength: restrictions.minLength?.value,
            minExclusive: restrictions.minExclusive?.value,
            minInclusive: restrictions.minInclusive?.value,
            maxInclusive: restrictions.maxInclusive?.value,
            pattern: restrictions.pattern?.value,
            docs: docs,
          );
        }
      case SimpleTypeValueUnion():
        writeUnion(
          sink,
          name: name.toDartClassName(),
          types: [
            ...value.union.memberTypes,
            ...value.union.declaredTypes.map((type) => type.name),
          ].map((type) => type.toDartTypeName()).toList(growable: false),
          docs: docs,
        );
    }
  }
}

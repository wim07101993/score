import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

import '../xsd/attributes/attribute.dart';
import '../xsd/elements/element.dart';
import '../xsd/types/typed_mixin.dart';
import 'alias.dart';
import 'class.dart';
import 'code.dart';
import 'enum.dart';
import 'string_extensions.dart';

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
    // yield* attributes;
    // yield* attributeGroups.expand((group) => group.allAttributes);
  }

  Iterable<Element> get allElements sync* {
    // yield* elements;
    // yield* groups.expand((group) => group.allElements);
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
        // ...allElements.map(
        //   (element) => (
        //     element.type.dartTypeName,
        //     element.name.toPropertyName(),
        //     true,
        //     false,
        //   ),
        // ),
      ],
      baseType: null, // simpleContent?.extension?.base.name,
      interfaces: [
        // ...attributeGroups.map((group) => group.dartTypeName),
        // ...groups.map((group) => group.dartTypeName),
      ],
      docs: annotation?.documentation ?? const [],
    );
  }
}

extension SimpleTypeExtensions on SimpleType {
  void writeAsCode(IOSink sink) {
    final restrictions = this.restrictions;
    if (restrictions != null) {
      final enumerations = restrictions.enumerations;
      if (enumerations.isNotEmpty) {
        writeEnum(
          sink,
          docs: annotation?.documentation ?? const [],
          name: name.toDartClassName(),
          values: enumerations
              .map((e) => e.value.toEnumValueName())
              .toList(growable: false),
        );
      } else {
        writeAlias(
          sink,
          name: name.toDartClassName(),
          baseType: restrictions.base.dartTypeName,
          restrictions: restrictions.values
              .map((restriction) => '${restriction.type}: ${restriction.value}')
              .toList(growable: false),
          docs: annotation?.documentation ?? const [],
        );
      }
    }

    final union = this.union;
    if (union != null) {
      writeUnion(
        sink,
        name: name.toDartClassName(),
        types: [
          ...union.declaredTypes.map((type) => type.name),
        ].map((type) => type.toDartTypeName()).toList(growable: false),
        docs: annotation?.documentation ?? const [],
      );
    }
  }
}

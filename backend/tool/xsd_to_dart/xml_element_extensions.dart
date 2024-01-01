import 'package:dart_casing/dart_casing.dart';
import 'package:xml/xml.dart';

import 'code/alias.dart';
import 'code/enum.dart';
import 'code/union.dart';
import 'string_extensions.dart';

extension XsdXmlElementExtensions on XmlElement {
  String get typeName {
    return Casing.pascalCase(getAttribute('name')!);
  }

  String mustGetAttribute(String attributeName, String forElement) {
    final value = getAttribute(attributeName);
    if (value == null) {
      throw Exception('no $attributeName for $forElement');
    }
    return value;
  }

  Iterable<XmlElement> findChildElements(String localName) {
    return childElements.where((element) => element.name.local == localName);
  }

  /// ----------------------------------------------------
  /// FUNCTIONS TO CALL ON THE SIMPLE/COMPLEX TYPE ELEMENT
  /// ----------------------------------------------------

  Iterable<XmlElement> get annotationElements =>
      findChildElements('annotation');
  Iterable<XmlElement> get documentationElements => annotationElements
      .expand((annotation) => annotation.findChildElements('documentation'));

  Iterable<String> get documentation =>
      documentationElements.map((documentation) => documentation.innerText);

  XmlElement? get restrictionElement =>
      findChildElements('restriction').firstOrNull;
  Iterable<XmlElement> get enumerationElements =>
      restrictionElement?.findChildElements('enumeration') ?? [];

  Iterable<String> enumerations(String forType) {
    return enumerationElements
        .map((e) => e.mustGetAttribute('value', forType))
        .map(Casing.camelCase)
        .map((value) {
      return switch (value) {
        'continue' => 'continue_',
        'do' => 'do_',
        '' => 'none',
        String() => int.tryParse(value[0]) is int ? 'n$value' : value,
      };
    });
  }

  Enum toEnum() {
    final typeName = this.typeName;
    return Enum(
      name: typeName,
      values: enumerations(typeName).toList(growable: false),
      docs: documentation.toList(growable: false),
    );
  }

  String? minInclusive(String forType) {
    return restrictionElement
        ?.findChildElements('minInclusive')
        .firstOrNull
        ?.mustGetAttribute('value', forType);
  }

  String? maxInclusive(String forType) {
    return restrictionElement
        ?.findChildElements('maxInclusive')
        .firstOrNull
        ?.mustGetAttribute('value', forType);
  }

  String? pattern(String forType) {
    return restrictionElement
        ?.findChildElements('pattern')
        .firstOrNull
        ?.mustGetAttribute('value', forType);
  }

  Alias toAlias() {
    final typeName = this.typeName;
    final baseTypeName =
        restrictionElement?.mustGetAttribute('base', typeName).toDartTypeName();
    if (baseTypeName == null) {
      throw Exception('no base type for alias $typeName');
    }
    return Alias(
      name: typeName,
      baseType: baseTypeName,
      docs: documentation.toList(growable: false),
      minInclusive: minInclusive(typeName),
      maxInclusive: maxInclusive(typeName),
      pattern: pattern(typeName),
    );
  }

  XmlElement? get unionElement => findChildElements('union').firstOrNull;

  List<String> memberTypes(String forType) =>
      unionElement?.mustGetAttribute('memberTypes', forType).split(' ') ?? [];

  Union toUnion() {
    final typeName = this.typeName;
    return Union(
      name: typeName,
      docs: documentation.toList(growable: false),
      types: memberTypes(typeName),
    );
  }
}

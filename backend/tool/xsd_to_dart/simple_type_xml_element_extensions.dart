import 'package:dart_casing/dart_casing.dart';
import 'package:xml/xml.dart';

import 'code/code.dart';
import 'string_extensions.dart';
import 'xml_element_extensions.dart';
import 'xsd_xml_element_extensions.dart';

extension SimpleTypeXmlElementExtensions on XmlElement {
  XmlElement? get restrictionElement =>
      findChildElements('restriction').firstOrNull;
  XmlElement? get unionElement => findChildElements('union').firstOrNull;

  Iterable<XmlElement> get enumerationElements =>
      restrictionElement?.findChildElements('enumeration') ?? [];
  Iterable<XmlElement> get attributeElements => findChildElements('attribute');

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

  Iterable<String> memberTypes(String forType) {
    return unionElement
            ?.mustGetAttribute('memberTypes', forType)
            .split(' ')
            .map((type) => type.toDartTypeName()) ??
        [];
  }

  Enum toEnum() {
    final typeName = this.typeName;
    return Enum(
      name: typeName,
      values: enumerations(typeName).toList(growable: false),
      docs: documentation.toList(growable: false),
    );
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

  Union toUnion() {
    final typeName = this.typeName;
    return Union(
      name: typeName,
      docs: documentation.toList(growable: false),
      types: memberTypes(typeName).toList(growable: false),
    );
  }
}

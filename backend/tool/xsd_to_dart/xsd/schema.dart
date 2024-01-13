import 'package:xml/xml.dart';

import 'annotation.dart';
import 'attributes/attribute.dart';
import 'types/typed_mixin.dart';
import 'xml_extensions.dart';

class Schema
    with
        SimpleTypesOwnerMixin,
        ComplexTypesOwnerMixin,
        AttributesOwnerMixin,
        MultiAnnotatedMixin
    implements TypeDeclarer {
  const Schema({required this.xml});

  @override
  final XmlElement xml;

  @override
  String get name => 'schema';

  @override
  Iterable<XsdType> get declaredTypes sync* {
    yield* simpleTypes.expand((simpleType) => simpleType.declaredTypes);
    yield* simpleTypes;
    yield* complexTypes.expand((complexType) => complexType.declaredTypes);
    yield* attributes.expand((attribute) => attribute.declaredTypes);
    yield* attributeGroups.expand((group) => group.declaredTypes);
  }
}

mixin NamedMixin implements XmlOwner {
  static const String nameAttributeName = 'name';
  String get name => xml.mustGetAttribute(nameAttributeName);
}

mixin ValueOwnerMixin implements XmlOwner {
  static const String valueAttributeName = 'value';
  String get value => xml.mustGetAttribute(valueAttributeName);
}

mixin IdNodeMixin implements XmlOwner {
  static const String idAttributeName = 'id';
  String? get id => xml.getAttribute(idAttributeName);
}

mixin OccurrenceMixin implements XmlOwner {
  bool get isNullable => minOccurs == '0';
  String get minOccurs => xml.getAttribute('minOccurs') ?? '1';
  String get maxOccurs => xml.getAttribute('maxOccurs') ?? '1';
}

abstract class XmlOwner {
  XmlElement get xml;
}

abstract class TypeDeclarer {
  Iterable<XsdType> get declaredTypes;
}

abstract class XsdNode implements XmlOwner {
  const XsdNode({required this.xml});

  @override
  final XmlElement xml;

  Annotation? get annotation {
    final element = xml.findChildElement(Annotation.xmlName);
    return element == null ? null : Annotation(xml: element);
  }
}

enum XmlDataTypes { string, decimal, integer, boolean, date, time }

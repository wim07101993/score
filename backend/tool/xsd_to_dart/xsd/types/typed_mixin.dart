import 'package:xml/xml.dart';

import '../attributes/attribute.dart';
import '../content/simple_content.dart';
import '../elements/element.dart';
import '../restriction/restriction.dart';
import '../schema.dart';
import '../xml_extensions.dart';
import 'union.dart';

part 'typed_mixin.complex_type.dart';
part 'typed_mixin.simple_type.dart';

mixin TypedMixin implements NamedMixin, XmlOwner {
  XsdType get type => _getTypeFromXml('type', xml, this);
}

mixin BasedMixin implements NamedMixin, XmlOwner {
  XsdType get base => _getTypeFromXml('base', xml, this);
}

XsdType _getTypeFromXml(
  String typeXmlName,
  XmlElement xml,
  NamedMixin parent,
) {
  final typeReferenceXml = xml.getAttribute(typeXmlName);
  if (typeReferenceXml != null) {
    return TypeReference(name: typeReferenceXml);
  }
  final simpleTypeXml = xml.findChildElement(SimpleType.xmlName);
  if (simpleTypeXml != null) {
    return SimpleType(xml: simpleTypeXml, parent: parent);
  }
  final complexTypeXml = xml.findChildElement(ComplexType.xmlName);
  if (complexTypeXml != null) {
    return ComplexType(xml: complexTypeXml, parent: parent);
  }
  throw Exception('no type found:\n$xml');
}

sealed class XsdType {
  String get name;
}

class TypeReference implements XsdType {
  const TypeReference({
    required this.name,
  });

  @override
  final String name;
}

extension XsdTypeExtensions on XsdType {
  Iterable<XsdType> get declaredSubTypes {
    final type = this;
    return type is TypeDeclarer
        ? (type as TypeDeclarer).declaredTypes
        : const [];
  }
}

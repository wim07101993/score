import 'package:xml/xml.dart';

import '../annotation.dart';
import '../attributes/attribute.dart';
import '../attributes/attribute_group.dart';
import '../content/complex_content.dart';
import '../content/simple_content.dart';
import '../elements/choice.dart';
import '../elements/group.dart';
import '../elements/sequence.dart';
import '../restriction/restriction.dart';
import '../schema.dart';
import '../xml_extensions.dart';

part 'typed_mixin.complex_type.dart';
part 'typed_mixin.simple_type.dart';
part 'typed_mixin.union.dart';

mixin TypedMixin implements NamedMixin, XmlOwner {
  XsdType get type => getTypeFromXml('type', xml, 'typed');
}

mixin BasedMixin implements NamedMixin, XmlOwner {
  XsdType get base => getTypeFromXml('base', xml, 'based');
}

XsdType getTypeFromXml(
  String typeXmlName,
  XmlElement xml,
  String parentName,
) {
  final typeReferenceXml = xml.getAttribute(typeXmlName);
  if (typeReferenceXml != null) {
    return TypeReference(name: typeReferenceXml);
  }
  final simpleTypeXml = xml.findChildElement(SimpleType.xmlName);
  if (simpleTypeXml != null) {
    return SimpleType.fromXml(xml: simpleTypeXml, parentName: parentName);
  }
  final complexTypeXml = xml.findChildElement(ComplexType.xmlName);
  if (complexTypeXml != null) {
    return ComplexType.fromXml(complexTypeXml);
  }
  throw Exception('no type found:\n$xml');
}

sealed class XsdType implements Named {}

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

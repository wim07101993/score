import '../attributes/attribute.dart';
import '../content/simple_content.dart';
import '../elements/element.dart';
import '../restriction/restriction.dart';
import '../schema.dart';
import '../xml_extensions.dart';
import 'union.dart';

part 'typed_mixin.complex_type.dart';
part 'typed_mixin.simple_type.dart';

mixin TypedMixin implements XmlOwner {
  String get typeXmlName => 'type';

  XsdType get type {
    final typeReferenceXml = xml.getAttribute(typeXmlName);
    if (typeReferenceXml != null) {
      return TypeReference(typeName: typeReferenceXml);
    }
    final simpleTypeXml = xml.findChildElement(SimpleType.xmlName);
    if (simpleTypeXml != null) {
      return SimpleType(xml: simpleTypeXml);
    }
    final complexTypeXml = xml.findChildElement(ComplexType.xmlName);
    if (complexTypeXml != null) {
      return ComplexType(xml: complexTypeXml);
    }
    throw Exception('no type found:\n$xml');
  }
}

sealed class XsdType {}

class TypeReference implements XsdType {
  const TypeReference({required this.typeName});

  final String typeName;
}

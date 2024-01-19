import 'package:xml/xml.dart';

import '../annotation.dart';
import '../types/typed_mixin.dart';

class Element {
  const Element({
    required this.name,
    required this.type,
    required this.minOccurs,
    required this.maxOccurs,
    required this.annotation,
  });

  factory Element.fromXml(XmlElement xml) {
    String? name;
    XsdType? type;
    int? minOccurs;
    int? maxOccurs;
    Annotation? annotation;

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'name':
          name = attribute.value;
        case 'type':
          type = TypeReference(name: attribute.value);
        case 'minOccurs':
          minOccurs = int.parse(attribute.value);
        case 'maxOccurs':
          if (attribute.value == 'unbounded') {
            maxOccurs = 0xFFFFFFFFFFF; // practically infinite
          } else {
            maxOccurs = int.parse(attribute.value);
          }
        default:
          throw Exception(
            'unknown element attribute ${attribute.name.local}',
          );
      }
    }

    if (name == null) {
      throw Exception('no name for element $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Annotation.xmlName:
          annotation = Annotation.fromXml(child);
        case ComplexType.xmlName:
          type = ComplexType.fromXml(xml: child, parentName: name);
        default:
          throw Exception('unknown element element ${child.name.local}');
      }
    }
    if (type == null) {
      throw Exception('no type for element $xml');
    }

    return Element(
      name: name,
      type: type,
      minOccurs: minOccurs ?? 0,
      maxOccurs: maxOccurs ?? 1,
      annotation: annotation,
    );
  }

  static const String xmlName = 'element';

  final String name;
  final XsdType type;
  final int minOccurs;
  final int maxOccurs;
  final Annotation? annotation;

  Iterable<XsdType> get declaredTypes {
    final type = this.type;
    switch (type) {
      case TypeReference():
        return const [];
      case ComplexType():
        return type.declaredTypes;
      case SimpleType():
        return type.declaredTypes;
      case Union():
        return type.declaredTypes;
    }
  }
}

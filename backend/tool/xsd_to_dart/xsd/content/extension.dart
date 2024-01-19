import 'package:xml/xml.dart';

import '../attributes/attribute.dart';
import '../attributes/attribute_group.dart';
import '../schema.dart';
import '../types/typed_mixin.dart';

class Extension implements TypeDeclarer {
  const Extension({
    required this.base,
    this.attributeGroups = const [],
    this.attributes = const [],
  });

  factory Extension.fromXml(XmlElement xml) {
    TypeReference? base;
    final attributes = <Attribute>[];
    final attributeGroups = <AttributeGroup>[];

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'base':
          base = TypeReference(name: attribute.value);
        default:
          throw Exception(
            'unknown extension attribute ${attribute.name.local}',
          );
      }
    }
    if (base == null) {
      throw Exception('no base for extension $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Attribute.xmlName:
          attributes.add(Attribute.fromXml(child));
        case AttributeGroup.xmlName:
          attributeGroups.add(AttributeGroup.fromXml(child));
        default:
          throw Exception('unknown extension element ${child.name.local}');
      }
    }

    return Extension(
      base: base,
      attributes: attributes,
      attributeGroups: attributeGroups,
    );
  }

  static const String xmlName = 'extension';

  final TypeReference base;
  final List<Attribute> attributes;
  final List<AttributeGroup> attributeGroups;

  @override
  Iterable<XsdType> get declaredTypes sync* {
    yield* attributes.expand((attribute) => attribute.declaredTypes);
    yield* attributeGroups.expand((group) => group.declaredTypes);
  }
}

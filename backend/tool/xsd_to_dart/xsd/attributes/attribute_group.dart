import 'package:xml/xml.dart';

import '../annotation.dart';
import '../schema.dart';
import '../types/typed_mixin.dart';
import 'attribute.dart';

late AttributeGroup Function(String xmlName) resolveAttributeGroup;

class AttributeGroup implements TypeDeclarer {
  const AttributeGroup({
    required this.name,
    required this.attributes,
    this.attributeGroups = const [],
    this.annotation,
  });

  factory AttributeGroup.fromXml(XmlElement xml) {
    String? name;
    Annotation? annotation;
    final attributes = <Attribute>[];
    final attributeGroups = <AttributeGroup>[];

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'name':
          name = attribute.value;
        case 'ref':
          return AttributeGroupReference(reference: attribute.value);
        default:
          throw Exception(
            'unknown attribute group attribute ${attribute.name.local}',
          );
      }
    }

    if (name == null) {
      throw Exception('no name for attribute group $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Annotation.xmlName:
          annotation = Annotation.fromXml(child);
        case Attribute.xmlName:
          attributes.add(Attribute.fromXml(child));
        case AttributeGroup.xmlName:
          attributeGroups.add(AttributeGroup.fromXml(child));
        default:
          throw Exception(
            'unknown attribute group element ${child.name.local}',
          );
      }
    }

    return AttributeGroup(
      name: name,
      annotation: annotation,
      attributes: attributes,
      attributeGroups: attributeGroups,
    );
  }

  static const String xmlName = 'attributeGroup';

  final String name;
  final Annotation? annotation;
  final List<Attribute> attributes;
  final List<AttributeGroup> attributeGroups;

  @override
  Iterable<XsdType> get declaredTypes sync* {
    yield* attributes.expand((attribute) => attribute.declaredTypes);
    yield* attributeGroups.expand((group) => group.declaredTypes);
  }
}

class AttributeGroupReference implements AttributeGroup {
  AttributeGroupReference({
    required this.reference,
  });

  final String reference;

  late final AttributeGroup refersTo = resolveAttributeGroup(reference);

  @override
  List<Attribute> get attributes => refersTo.attributes;

  @override
  List<AttributeGroup> get attributeGroups => refersTo.attributeGroups;

  @override
  String get name => reference;

  @override
  Annotation? get annotation => throw UnimplementedError();

  @override
  Iterable<XsdType> get declaredTypes => const [];
}

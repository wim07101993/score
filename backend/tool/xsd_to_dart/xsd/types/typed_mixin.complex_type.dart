part of 'typed_mixin.dart';

class ComplexType implements XsdType, TypeDeclarer {
  const ComplexType({
    required this.name,
    this.annotation,
    this.simpleContent,
    this.attributes = const [],
    this.attributesGroups = const [],
    this.choices = const [],
    this.sequences = const [],
    this.groups = const [],
    this.complexContent = const [],
  });

  factory ComplexType.fromXml(XmlElement xml) {
    String? name;
    Annotation? annotation;
    SimpleContent? simpleContent;
    final List<Attribute> attributes = [];
    final List<AttributeGroup> attributesGroups = [];
    final List<Choice> choices = [];
    final List<Sequence> sequences = [];
    final List<Group> groups = [];
    final List<ComplexContent> complexContent = [];

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'name':
          name = attribute.value;
        default:
          throw Exception(
            'unknown simpleType attribute ${attribute.name.local}',
          );
      }
    }
    if (name == null) {
      throw Exception('no name for complex type $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Annotation.xmlName:
          annotation = Annotation.fromXml(child);
        case SimpleContent.xmlName:
          simpleContent = SimpleContent.fromXml(child);
        case ComplexContent.xmlName:
          complexContent.add(ComplexContent.fromXml(child));
        case Attribute.xmlName:
          attributes.add(Attribute.fromXml(child));
        case AttributeGroup.xmlName:
          attributesGroups.add(AttributeGroup.fromXml(child));
        case Choice.xmlName:
          choices.add(Choice.fromXml(xml: child, parentName: name));
        case Sequence.xmlName:
          sequences.add(Sequence(xml: child));
        case Group.xmlName:
          groups.add(Group.fromXml(child));
        default:
          throw Exception('unknown schema element ${child.name.local}');
      }
    }

    return ComplexType(
      name: name,
      annotation: annotation,
      simpleContent: simpleContent,
      attributes: attributes,
      attributesGroups: attributesGroups,
      choices: choices,
      sequences: sequences,
      groups: groups,
      complexContent: complexContent,
    );
  }

  static const String xmlName = 'complexType';

  @override
  final String name;
  final Annotation? annotation;
  final SimpleContent? simpleContent;
  final List<Attribute> attributes;
  final List<AttributeGroup> attributesGroups;
  final List<Choice> choices;
  final List<Sequence> sequences;
  final List<Group> groups;
  final List<ComplexContent> complexContent;

  @override
  Iterable<XsdType> get declaredTypes sync* {}
}

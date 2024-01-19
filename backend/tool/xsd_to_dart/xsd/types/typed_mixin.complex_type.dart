part of 'typed_mixin.dart';

class ComplexType extends XsdType {
  const ComplexType({
    required this.name,
    this.annotation,
    this.simpleContent,
    this.complexContent,
    this.attributes = const [],
    this.attributesGroups = const [],
    this.choices = const [],
    this.sequences = const [],
    this.groups = const [],
  });

  factory ComplexType.fromXml({
    required XmlElement xml,
    required String parentName,
  }) {
    String? name;
    Annotation? annotation;
    SimpleContent? simpleContent;
    ComplexContent? complexContent;
    final List<Attribute> attributes = [];
    final List<AttributeGroup> attributesGroups = [];
    final List<Choice> choices = [];
    final List<Sequence> sequences = [];
    final List<Group> groups = [];

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
    name ??= '${parentName}_type';

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Annotation.xmlName:
          annotation = Annotation.fromXml(child);
        case SimpleContent.xmlName:
          simpleContent = SimpleContent.fromXml(child);
        case ComplexContent.xmlName:
          complexContent = ComplexContent.fromXml(child);
        case Attribute.xmlName:
          attributes.add(Attribute.fromXml(child));
        case AttributeGroup.xmlName:
          attributesGroups.add(AttributeGroup.fromXml(child));
        case Choice.xmlName:
          choices.add(Choice.fromXml(xml: child, parentName: name));
        case Sequence.xmlName:
          sequences.add(Sequence.fromXml(xml: child, parentName: name));
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
      complexContent: complexContent,
      attributes: attributes,
      attributesGroups: attributesGroups,
      choices: choices,
      sequences: sequences,
      groups: groups,
    );
  }

  static const String xmlName = 'complexType';

  @override
  final String name;
  final Annotation? annotation;
  final SimpleContent? simpleContent;
  final ComplexContent? complexContent;
  final List<Attribute> attributes;
  final List<AttributeGroup> attributesGroups;
  final List<Choice> choices;
  final List<Sequence> sequences;
  final List<Group> groups;

  Iterable<XsdType> get declaredTypes sync* {
    yield* choices.expand((choices) => choices.declaredTypes);
    yield* groups.expand((groups) => groups.declaredTypes);
    yield* sequences.expand((sequences) => sequences.declaredTypes);
  }
}

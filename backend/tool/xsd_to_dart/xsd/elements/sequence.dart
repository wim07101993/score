import 'package:xml/xml.dart';

import '../types/typed_mixin.dart';
import 'choice.dart';
import 'element.dart';
import 'group.dart';

class Sequence {
  const Sequence({
    required this.name,
    required this.minOccurs,
    required this.maxOccurs,
    required this.elements,
    required this.choices,
    required this.groups,
    required this.sequences,
  });

  factory Sequence.fromXml({
    required XmlElement xml,
    required String parentName,
  }) {
    int? minOccurs;
    int? maxOccurs;
    final List<Element> elements = [];
    final List<Sequence> sequences = [];
    final List<Choice> choices = [];
    final List<Group> groups = [];

    final name = '${parentName}_sequence';

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
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
            'unknown sequence attribute ${attribute.name.local}',
          );
      }
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Element.xmlName:
          elements.add(Element.fromXml(child));
        case Sequence.xmlName:
          sequences.add(Sequence.fromXml(xml: child, parentName: name));
        case Choice.xmlName:
          choices.add(Choice.fromXml(xml: child, parentName: name));
        case Group.xmlName:
          groups.add(Group.fromXml(child));
        default:
          throw Exception('unknown sequence element ${child.name.local}');
      }
    }
    return Sequence(
      name: name,
      minOccurs: minOccurs ?? 0,
      maxOccurs: maxOccurs ?? 1,
      elements: elements,
      choices: choices,
      groups: groups,
      sequences: sequences,
    );
  }

  static const String xmlName = 'sequence';

  final String name;
  final int minOccurs;
  final int maxOccurs;
  final List<Element> elements;
  final List<Choice> choices;
  final List<Group> groups;
  final List<Sequence> sequences;

  Iterable<XsdType> get declaredTypes sync* {
    yield* elements.expand((element) => element.declaredTypes);
    yield* choices.expand((choices) => choices.declaredTypes);
    yield* groups.expand((groups) => groups.declaredTypes);
    yield* sequences.expand((sequences) => sequences.declaredTypes);
  }
}

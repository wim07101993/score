import 'package:xml/xml.dart';

import '../schema.dart';
import '../types/typed_mixin.dart';
import 'element.dart';
import 'sequence.dart';

class Choice implements TypeDeclarer {
  const Choice({
    required this.name,
    required this.minOccurs,
    required this.maxOccurs,
    required this.elements,
    required this.sequences,
    required this.choices,
  });

  factory Choice.fromXml({
    required XmlElement xml,
    required String parentName,
  }) {
    int? minOccurs;
    int? maxOccurs;
    final List<Element> elements = [];
    final List<Sequence> sequences = [];
    final List<Choice> choices = [];

    final name = '${parentName}_choice';

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
            'unknown choice attribute ${attribute.name.local}',
          );
      }
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Element.xmlName:
          elements.add(Element(xml: child));
        case Sequence.xmlName:
          sequences.add(Sequence(xml: child));
        case Choice.xmlName:
          choices.add(Choice.fromXml(xml: child, parentName: name));
        default:
          throw Exception('unknown choice element ${child.name.local}');
      }
    }

    return Choice(
      name: name,
      minOccurs: minOccurs ?? 0,
      maxOccurs: maxOccurs ?? 1,
      elements: elements,
      sequences: sequences,
      choices: choices,
    );
  }

  static const String xmlName = 'choice';

  final String name;
  final int minOccurs;
  final int maxOccurs;
  final List<Element> elements;
  final List<Sequence> sequences;
  final List<Choice> choices;

  @override
  Iterable<XsdType> get declaredTypes => const [];
}

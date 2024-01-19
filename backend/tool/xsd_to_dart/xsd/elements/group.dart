import 'package:xml/xml.dart';

import '../annotation.dart';
import '../types/typed_mixin.dart';
import 'sequence.dart';

late Group Function(String xmlName) resolveGroup;

class Group {
  const Group({
    required this.name,
    required this.annotation,
    required this.sequences,
  });

  factory Group.fromXml(XmlElement xml) {
    String? name;
    Annotation? annotation;
    final List<Sequence> sequences = [];

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'name':
          name = attribute.value;
        case 'ref':
          return GroupReference(reference: attribute.value);
        default:
          throw Exception(
            'unknown choice attribute ${attribute.name.local}',
          );
      }
    }

    if (name == null) {
      throw Exception('no name for group $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Annotation.xmlName:
          annotation = Annotation.fromXml(child);
        case Sequence.xmlName:
          sequences.add(Sequence.fromXml(xml: child, parentName: name));
        default:
          throw Exception('unknown choice element ${child.name.local}');
      }
    }

    return Group(
      name: name,
      annotation: annotation,
      sequences: sequences,
    );
  }

  static const String xmlName = 'group';

  final String name;
  final Annotation? annotation;
  final List<Sequence> sequences;

  Iterable<XsdType> get declaredTypes {
    return sequences.expand((sequences) => sequences.declaredTypes);
  }
}

class GroupReference implements Group {
  GroupReference({
    required this.reference,
  });

  final String reference;

  late final Group refersTo = resolveGroup(reference);

  @override
  String get name => refersTo.name;
  @override
  Annotation? get annotation => refersTo.annotation;
  @override
  List<Sequence> get sequences => refersTo.sequences;

  @override
  Iterable<XsdType> get declaredTypes => const [];
}

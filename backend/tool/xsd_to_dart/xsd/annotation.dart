import 'package:xml/xml.dart';

class Annotation {
  const Annotation({
    this.documentation = const [],
  });

  factory Annotation.fromXml(
    XmlElement xml,
  ) {
    final List<String> documentation = [];

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        default:
          throw Exception(
            'unknown simpleType attribute ${attribute.name.local}',
          );
      }
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case 'documentation':
          documentation.add(child.innerText);
        default:
          throw Exception('unknown annotation element ${child.name.local}');
      }
    }

    return Annotation(documentation: documentation);
  }

  static const String xmlName = 'annotation';

  final List<String> documentation;
}

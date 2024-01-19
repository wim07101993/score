import 'package:xml/xml.dart';

class Enumeration {
  const Enumeration({
    required this.value,
  });

  factory Enumeration.fromXml(XmlElement xml) {
    String? value;
    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'value':
          value = attribute.value;
        default:
          throw Exception(
            'unknown enumeration attribute ${attribute.name.local}',
          );
      }
    }

    if (value == null) {
      throw Exception('no value for enumeration $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        default:
          throw Exception('unknown enumeration element ${child.name.local}');
      }
    }

    return Enumeration(value: value);
  }

  final String value;
}

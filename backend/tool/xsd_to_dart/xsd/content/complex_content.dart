import 'package:xml/xml.dart';

import 'extension.dart';

class ComplexContent {
  const ComplexContent({
    required this.extension,
  });

  factory ComplexContent.fromXml(XmlElement xml) {
    Extension? extension;

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        default:
          throw Exception(
            'unknown extension attribute ${attribute.name.local}',
          );
      }
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Extension.xmlName:
          extension = Extension.fromXml(child);
        default:
          throw Exception('unknown schema element ${child.name.local}');
      }
    }

    if (extension == null) {
      throw Exception('no extension for complex content $xml');
    }

    return ComplexContent(
      extension: extension,
    );
  }

  static const String xmlName = 'complexContent';

  final Extension extension;
}

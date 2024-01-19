import 'package:xml/xml.dart';

import '../schema.dart';
import '../types/typed_mixin.dart';
import 'extension.dart';

class SimpleContent implements TypeDeclarer {
  const SimpleContent({
    required this.extension,
  });

  factory SimpleContent.fromXml(XmlElement xml) {
    Extension? extension;

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        default:
          throw Exception(
            'unknown simple content attribute ${attribute.name.local}',
          );
      }
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Extension.xmlName:
          extension = Extension.fromXml(child);
        default:
          throw Exception('unknown simple content element ${child.name.local}');
      }
    }

    if (extension == null) {
      throw Exception('no extension for simple content $xml');
    }

    return SimpleContent(
      extension: extension,
    );
  }

  static const String xmlName = 'simpleContent';

  final Extension extension;

  @override
  Iterable<XsdType> get declaredTypes => extension.declaredTypes;
}

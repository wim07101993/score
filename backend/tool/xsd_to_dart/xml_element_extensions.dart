import 'package:dart_casing/dart_casing.dart';
import 'package:xml/xml.dart';

extension XsdXmlElementExtensions on XmlElement {
  String get typeName {
    final name = Casing.pascalCase(getAttribute('name')!);
    return switch (name) {
      'String' => 'GuitarString',
      String() => name,
    };
  }

  String mustGetAttribute(String attributeName, String forElement) {
    final value = getAttribute(attributeName);
    if (value == null) {
      throw Exception('no $attributeName for $forElement');
    }
    return value;
  }

  Iterable<XmlElement> findChildElements(String localName) {
    return childElements.where((element) => element.name.local == localName);
  }
}

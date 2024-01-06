import 'package:xml/xml.dart';

extension XsdXmlExtensions on XmlElement {
  String mustGetAttribute(String attributeName) {
    final value = getAttribute(attributeName);
    if (value == null) {
      throw Exception('no $attributeName in element $this');
    }
    return value;
  }

  XmlElement? findChildElement(String localName) {
    return findChildElements(localName).singleOrNull;
  }

  XmlElement mustFindChildElement(String localName) {
    return findChildElements(localName).single;
  }

  Iterable<XmlElement> findChildElements(String localName) {
    return childElements.where((element) => element.name.local == localName);
  }
}

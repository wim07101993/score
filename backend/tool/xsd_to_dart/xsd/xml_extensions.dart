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
    return findChildElements(localName).firstOrNull;
  }

  XmlElement mustFindChildElement(String localName) {
    final child = findChildElements(localName).firstOrNull;
    if (child == null) {
      throw Exception('no child found with name $localName in $name');
    }
    return child;
  }

  Iterable<XmlElement> findChildElements(String localName) {
    return childElements.where((element) => element.name.local == localName);
  }
}

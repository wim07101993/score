import 'package:xml/xml.dart';

import 'code/code.dart';
import 'complex_type_xml_element_extensions.dart';
import 'simple_type_xml_element_extensions.dart';
import 'xml_element_extensions.dart';

Iterable<Type> createCodeFromXmlElement(XmlElement element) sync* {
  switch (element.name.local) {
    case 'simpleType':
      yield createSimpleType(element);
    case 'complexType':
      yield* createComplexType(element);
    case 'attributeGroup':
      yield element.toInterface();
    case 'group':
      yield* createComplexInterface(element);
  }
}

Type createSimpleType(XmlElement element) {
  final typeName = element.typeName;
  final restrictionElement = element.restrictionElement;
  if (restrictionElement != null) {
    switch (restrictionElement.mustGetAttribute('base', typeName)) {
      case 'xs:token':
      case 'xs:string':
        if (element.enumerationElements.isNotEmpty) {
          return element.toEnum();
        } else {
          return element.toAlias();
        }

      default:
        return element.toAlias();
    }
  }

  if (element.unionElement != null) {
    return element.toUnion();
  }

  throw Exception("don't know what to do with element $typeName:\n$element");
}

Iterable<Type> createComplexType(XmlElement element) sync* {
  yield element.toClass();
}

Iterable<Type> createComplexInterface(XmlElement element) sync* {
  yield element.toInterface();
}

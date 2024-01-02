import 'package:xml/xml.dart';

import 'code/code.dart';
import 'xml/complex_type_xml_element_extensions.dart';
import 'xml/simple_type_xml_element_extensions.dart';
import 'xml/xml_element_extensions.dart';

List<XmlElement> failedElements = [];

Iterable<Type> createCodeFromXsdDoc(XmlDocument doc) sync* {
  var todo = doc.rootElement.childElements;
  var failed = <XmlElement>[];
  final exceptions = [];

  while (failed.isNotEmpty || todo.isNotEmpty) {
    for (final element in todo) {
      try {
        yield* createCodeFromXmlElement(element);
      } catch (exception) {
        exceptions.add(exception);
        failed.add(element);
      }
    }

    if (failed.length == todo.length) {
      throw exceptions;
    }
    exceptions.clear();
    todo = failed;
    failed = <XmlElement>[];
  }
}

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

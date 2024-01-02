import 'package:xml/xml.dart';

import 'xml_element_extensions.dart';

extension XsdXmlElementExtensions on XmlElement {
  Iterable<XmlElement> get annotationElements =>
      findChildElements('annotation');
  Iterable<XmlElement> get documentationElements => annotationElements
      .expand((annotation) => annotation.findChildElements('documentation'));

  Iterable<String> get documentation =>
      documentationElements.map((documentation) => documentation.innerText);
}

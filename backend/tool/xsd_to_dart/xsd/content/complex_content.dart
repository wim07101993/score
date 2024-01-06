import '../schema.dart';
import '../xml_extensions.dart';
import 'extension.dart';

class ComplexContent extends XsdNode with ExtensionOwnerMixin {
  ComplexContent({required super.xml});

  static const String xmlName = 'complexContent';
}

mixin ComplexContentOwner implements XmlOwner {
  ComplexContent? get complexContent {
    final child = xml.findChildElement(ComplexContent.xmlName);
    return child == null ? null : ComplexContent(xml: child);
  }
}

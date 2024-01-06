import '../schema.dart';
import '../xml_extensions.dart';
import 'extension.dart';

class SimpleContent extends XsdNode with ExtensionOwnerMixin {
  const SimpleContent({required super.xml});
}

mixin SimpleContentOwnerMixin implements XmlOwner {
  SimpleContent? get simpleContent {
    final element = xml.findChildElement('simpleContent');
    return element == null ? null : SimpleContent(xml: element);
  }
}

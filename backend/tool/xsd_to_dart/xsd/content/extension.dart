import '../attributes/attribute.dart';
import '../schema.dart';
import '../xml_extensions.dart';

class Extension extends XsdNode with BasedMixin, AttributesOwnerMixin {
  const Extension({required super.xml});

  static const String xmlName = 'extension';
}

mixin ExtensionOwnerMixin implements XmlOwner {
  Extension? get extension {
    final element = xml.findChildElement(Extension.xmlName);
    return element == null ? null : Extension(xml: element);
  }
}

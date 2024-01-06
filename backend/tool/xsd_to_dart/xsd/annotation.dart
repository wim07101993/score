import 'schema.dart';
import 'xml_extensions.dart';

class Annotation extends XsdNode with IdNodeMixin {
  const Annotation({required super.xml});

  static const String xmlName = 'annotation';

  List<String> get documentations => xml
      .findChildElements('documentation')
      .map((element) => element.value)
      .whereType<String>()
      .toList(growable: false);
}

mixin MultiAnnotatedMixin implements XmlOwner {
  List<Annotation> get annotations => xml
      .findChildElements(Annotation.xmlName)
      .map((child) => Annotation(xml: child))
      .toList(growable: false);
}

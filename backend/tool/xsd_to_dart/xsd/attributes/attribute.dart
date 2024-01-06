import '../../xml/xml_element_extensions.dart';
import '../schema.dart';
import '../types/reference.dart';
import '../types/typed_mixin.dart';
import 'attribute_group.dart';

late Attribute Function(String xmlName) resolveAttribute;

class Attribute extends XsdNode with NamedMixin, TypedMixin {
  const Attribute({required super.xml});

  String? get defaultValue => xml.getAttribute('default');
  String? get fixedValue => xml.getAttribute('fixed');
  bool get isRequired => xml.getAttribute('use') == 'required';
}

mixin AttributesOwnerMixin implements XmlOwner {
  Iterable<Attribute> get attributes =>
      xml.findChildElements('simpleType').map((element) => Attribute(xml: xml));

  Iterable<AttributeGroup> get attributeGroups => xml
      .findChildElements(AttributeGroup.xmlName)
      .map(
        (child) => child.getAttribute(ReferenceMixin.xmlName) == null
            ? AttributeGroup(xml: child)
            : AttributeGroupReference(xml: child),
      )
      .toList(growable: false);
}

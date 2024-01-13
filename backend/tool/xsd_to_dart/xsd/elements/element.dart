import '../schema.dart';
import '../types/typed_mixin.dart';
import '../xml_extensions.dart';
import 'choice.dart';
import 'group.dart';
import 'sequence.dart';

class Element extends XsdNode
    with OccurrenceMixin, NamedMixin, TypedMixin
    implements TypeDeclarer {
  const Element({required super.xml});

  static const String xmlName = 'element';

  @override
  Iterable<XsdType> get declaredTypes {
    print('getting types from element $name');
    return type.declaredSubTypes;
  }
}

mixin ElementsOwnerMixin implements XmlOwner {
  Iterable<Element> get elements => xml
      .findChildElements(Element.xmlName)
      .map((child) => Element(xml: child));

  Iterable<Choice> get choices =>
      xml.findChildElements(Choice.xmlName).map((child) => Choice(xml: child));

  Iterable<Group> get groups =>
      xml.findChildElements(Group.xmlName).map((child) => Group(xml: child));

  Sequence? get sequence {
    final child = xml.findChildElement(Sequence.xmlName);
    return child == null ? null : Sequence(xml: child);
  }
}

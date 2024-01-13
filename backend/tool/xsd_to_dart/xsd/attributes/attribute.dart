import '../schema.dart';
import '../types/reference.dart';
import '../types/typed_mixin.dart';
import '../xml_extensions.dart';
import 'attribute_group.dart';

late Attribute Function(String xmlName) resolveAttribute;

class Attribute extends XsdNode
    with NamedMixin, TypedMixin
    implements TypeDeclarer {
  const Attribute({required super.xml});

  static const String xmlName = 'attribute';

  String? get defaultValue => xml.getAttribute('default');
  String? get fixedValue => xml.getAttribute('fixed');
  bool get isRequired => xml.getAttribute('use') == 'required';

  @override
  String get name {
    final reference = xml.getAttribute('ref');
    return reference != null ? reference.split(':').last : super.name;
  }

  @override
  XsdType get type {
    if (xml.getAttribute('ref') != null) {
      return TypeReference(name: name);
    } else {
      return super.type;
    }
  }

  @override
  Iterable<XsdType> get declaredTypes {
    print('getting type from attribute $name ($type)');
    return type.declaredSubTypes;
  }
}

class AttributeReference extends XsdNode
    with ReferenceMixin<Attribute>
    implements Attribute {
  const AttributeReference({required super.xml});

  @override
  String? get defaultValue => xml.getAttribute('default');

  @override
  String? get fixedValue => xml.getAttribute('fixed');

  @override
  bool get isRequired => xml.getAttribute('use') == 'required';

  @override
  Attribute get refersTo => resolveAttribute(reference);

  @override
  String get name => reference;

  @override
  XsdType get type => refersTo.type;

  @override
  Iterable<XsdType> get declaredTypes => const [];
}

mixin AttributesOwnerMixin implements XmlOwner {
  Iterable<Attribute> get attributes => xml
      .findChildElements(Attribute.xmlName)
      .map((child) => Attribute(xml: child));

  Iterable<AttributeGroup> get attributeGroups => xml
      .findChildElements(AttributeGroup.xmlName)
      .map(
        (child) => child.getAttribute(ReferenceMixin.xmlName) == null
            ? AttributeGroup(xml: child)
            : AttributeGroupReference(xml: child),
      )
      .toList(growable: false);
}

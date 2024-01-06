part of 'typed_mixin.dart';

class SimpleType extends XsdNode
    with NamedMixin, IdNodeMixin
    implements XsdType {
  const SimpleType({required super.xml});

  static const String xmlName = 'simpleType';

  SimpleTypeValueChoice get value {
    var element = xml.findChildElement(Restriction.xmlName);
    if (element != null) {
      return SimpleTypeValueRestriction(xml: element);
    }
    element = xml.findChildElement(Union.xmlName);
    if (element != null) {
      return SimpleTypeValueUnion(xml: element);
    }
    throw Exception('no element found for value in $xml');
  }
}

mixin SimpleTypesOwnerMixin implements XmlOwner {
  Iterable<SimpleType> get simpleTypes => xml
      .findChildElements(SimpleType.xmlName)
      .map((element) => SimpleType(xml: xml));
}

sealed class SimpleTypeValueChoice {}

class SimpleTypeValueRestriction extends XsdNode
    with RestrictionOwnerMixin
    implements SimpleTypeValueChoice {
  const SimpleTypeValueRestriction({required super.xml});
}

class SimpleTypeValueUnion extends XsdNode
    with UnionOwnerMixin
    implements SimpleTypeValueChoice {
  const SimpleTypeValueUnion({required super.xml});
}

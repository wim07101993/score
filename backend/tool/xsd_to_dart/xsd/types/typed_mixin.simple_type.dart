part of 'typed_mixin.dart';

class SimpleType extends XsdNode
    with NamedMixin, IdNodeMixin
    implements XsdType, TypeDeclarer {
  const SimpleType({
    required super.xml,
    required this.parent,
  });

  static const String xmlName = 'simpleType';

  final NamedMixin parent;

  @override
  String get name =>
      xml.getAttribute(NamedMixin.nameAttributeName) ?? '${parent.name}-type';

  SimpleTypeValueChoice get value {
    var element = xml.findChildElement(Restrictions.xmlName);
    if (element != null) {
      return SimpleTypeValueRestriction(xml: xml);
    }
    element = xml.findChildElement(Union.xmlName);
    if (element != null) {
      return SimpleTypeValueUnion(xml: xml);
    }
    throw Exception('no element found for value in $xml');
  }

  @override
  Iterable<XsdType> get declaredTypes {
    final value = this.value;
    return switch (value) {
      SimpleTypeValueRestriction() => value.restriction.declaredTypes,
      SimpleTypeValueUnion() => value.union.declaredTypes,
    };
  }
}

mixin SimpleTypesOwnerMixin implements NamedMixin, XmlOwner {
  Iterable<SimpleType> get simpleTypes => xml
      .findChildElements(SimpleType.xmlName)
      .map((child) => SimpleType(xml: child, parent: this));
}

sealed class SimpleTypeValueChoice {}

class SimpleTypeValueRestriction extends XsdNode
    with RestrictionOwnerMixin, NamedMixin
    implements SimpleTypeValueChoice {
  const SimpleTypeValueRestriction({required super.xml});
}

class SimpleTypeValueUnion extends XsdNode
    with UnionOwnerMixin, NamedMixin
    implements SimpleTypeValueChoice {
  const SimpleTypeValueUnion({required super.xml});
}

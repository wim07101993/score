part of 'typed_mixin.dart';

class ComplexType extends XsdNode
    with
        SimpleContentOwnerMixin,
        ComplexTypesOwnerMixin,
        AttributesOwnerMixin,
        ElementsOwnerMixin,
        NamedMixin
    implements XsdType, TypeDeclarer {
  const ComplexType({
    required super.xml,
    required this.parent,
  });

  static const String xmlName = 'complexType';

  final NamedMixin parent;

  @override
  String get name =>
      xml.getAttribute(NamedMixin.nameAttributeName) ?? '${parent.name}-type';

  @override
  Iterable<XsdType> get declaredTypes sync* {
    final simpleContentTypes = simpleContent?.declaredTypes;
    if (simpleContentTypes != null) {
      yield* simpleContentTypes;
    }
    yield* complexTypes.expand((complexType) => complexType.declaredTypes);
    yield* attributes.expand((attribute) => attribute.declaredTypes);
    yield* attributeGroups.expand((group) => group.declaredTypes);
    yield* elements.expand((element) => element.declaredTypes);
  }
}

mixin ComplexTypesOwnerMixin implements NamedMixin, XmlOwner {
  Iterable<ComplexType> get complexTypes => xml
      .findChildElements(ComplexType.xmlName)
      .map((child) => ComplexType(xml: child, parent: this));
}

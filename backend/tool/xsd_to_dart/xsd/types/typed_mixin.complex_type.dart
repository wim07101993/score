part of 'typed_mixin.dart';

class ComplexType extends XsdNode
    with
        SimpleContentOwnerMixin,
        ComplexTypesOwnerMixin,
        AttributesOwnerMixin,
        ElementsOwnerMixin
    implements XsdType {
  const ComplexType({required super.xml});

  static const String xmlName = 'complexContent';
}

mixin ComplexTypesOwnerMixin implements XmlOwner {
  Iterable<ComplexType> get complexTypes => xml
      .findChildElements('complexType')
      .map((child) => ComplexType(xml: child));
}

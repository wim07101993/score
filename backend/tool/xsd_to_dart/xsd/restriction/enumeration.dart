part of 'restriction.dart';

class Enumeration extends XsdNode with ValueOwnerMixin implements Restriction {
  const Enumeration({required super.xml});

  static const String xmlName = 'enumeration';
}

mixin EnumeratedMixin implements XmlOwner {
  Enumeration get value => Enumeration(xml: xml);
}

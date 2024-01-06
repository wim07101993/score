import '../schema.dart';

class Enumeration extends XsdNode with ValueOwnerMixin {
  const Enumeration({required super.xml});

  static const String xmlName = 'enumeration';
}

mixin EnumeratedMixin implements XmlOwner {
  Enumeration get value => Enumeration(xml: xml);
}

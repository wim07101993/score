import '../schema.dart';

class MinInclusive extends XsdNode with ValueOwnerMixin {
  const MinInclusive({required super.xml});

  static const String xmlName = 'minInclusive';
}

class MaxInclusive extends XsdNode with ValueOwnerMixin {
  const MaxInclusive({required super.xml});

  static const String xmlName = 'maxInclusive';
}

class MinLength extends XsdNode with ValueOwnerMixin {
  const MinLength({required super.xml});

  static const String xmlName = 'minLength';
}

mixin MinInclusiveMixin implements XmlOwner {
  MinInclusive get value => MinInclusive(xml: xml);
}

mixin MaxInclusiveMixin implements XmlOwner {
  MaxInclusive get value => MaxInclusive(xml: xml);
}

mixin MinLengthMixin implements XmlOwner {
  MinLength get value => MinLength(xml: xml);
}

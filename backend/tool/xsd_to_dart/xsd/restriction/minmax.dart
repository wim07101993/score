part of 'restriction.dart';

class MinExclusive extends XsdNode with ValueOwnerMixin implements Restriction {
  const MinExclusive({required super.xml});

  static const String xmlName = 'minExclusive';
}

class MinInclusive extends XsdNode with ValueOwnerMixin implements Restriction {
  const MinInclusive({required super.xml});

  static const String xmlName = 'minInclusive';
}

class MaxInclusive extends XsdNode with ValueOwnerMixin implements Restriction {
  const MaxInclusive({required super.xml});

  static const String xmlName = 'maxInclusive';
}

class MinLength extends XsdNode with ValueOwnerMixin implements Restriction {
  const MinLength({required super.xml});

  static const String xmlName = 'minLength';
}

mixin MinInclusiveMixin implements XmlOwner {
  MinInclusive get value => MinInclusive(xml: xml);
}

mixin MinExclusiveMixin implements XmlOwner {
  MinExclusive get value => MinExclusive(xml: xml);
}

mixin MaxInclusiveMixin implements XmlOwner {
  MaxInclusive get value => MaxInclusive(xml: xml);
}

mixin MinLengthMixin implements XmlOwner {
  MinLength get value => MinLength(xml: xml);
}

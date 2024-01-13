part of 'restriction.dart';

class PatternRestriction extends XsdNode
    with ValueOwnerMixin
    implements Restriction {
  PatternRestriction({required super.xml});

  static const String xmlName = 'pattern';
}

mixin PatternMixin implements XmlOwner {
  PatternRestriction get value => PatternRestriction(xml: xml);
}

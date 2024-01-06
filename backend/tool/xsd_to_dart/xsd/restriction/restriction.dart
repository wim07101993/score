import '../schema.dart';
import '../xml_extensions.dart';
import 'enumeration.dart';
import 'minmax.dart';
import 'pattern.dart';

class Restriction extends XsdNode with BasedMixin {
  const Restriction({required super.xml});

  static const String xmlName = 'restriction';

  List<RestrictionValueChoice> get values {
    return xml.childElements.map<RestrictionValueChoice>((e) {
      var element = xml.findChildElement(Enumeration.xmlName);
      if (element != null) {
        return EnumeratedRestrictionValue(xml: element);
      }
      element = xml.findChildElement(MinInclusive.xmlName);
      if (element != null) {
        return MinInclusiveRestrictionValue(xml: element);
      }
      element = xml.findChildElement(MaxInclusive.xmlName);
      if (element != null) {
        return MaxInclusiveRestrictionValue(xml: element);
      }
      element = xml.findChildElement(PatternRestriction.xmlName);
      if (element != null) {
        return PatternRestrictionValue(xml: element);
      }
      throw Exception('no element found for value in $xml');
    }).toList(growable: false);
  }
}

mixin RestrictionOwnerMixin implements XmlOwner {
  Restriction? get restriction {
    final element = xml.findChildElement(Restriction.xmlName);
    return element == null ? null : Restriction(xml: element);
  }
}

sealed class RestrictionValueChoice {}

class EnumeratedRestrictionValue extends XsdNode
    with EnumeratedMixin
    implements RestrictionValueChoice {
  const EnumeratedRestrictionValue({required super.xml});
}

class MinInclusiveRestrictionValue extends XsdNode
    with MinInclusiveMixin
    implements RestrictionValueChoice {
  const MinInclusiveRestrictionValue({required super.xml});
}

class MaxInclusiveRestrictionValue extends XsdNode
    with MaxInclusiveMixin
    implements RestrictionValueChoice {
  const MaxInclusiveRestrictionValue({required super.xml});
}

class PatternRestrictionValue extends XsdNode
    with PatternMixin
    implements RestrictionValueChoice {
  const PatternRestrictionValue({required super.xml});
}

class MinLengthRestrictionValue extends XsdNode
    with MinLengthMixin
    implements RestrictionValueChoice {
  const MinLengthRestrictionValue({required super.xml});
}

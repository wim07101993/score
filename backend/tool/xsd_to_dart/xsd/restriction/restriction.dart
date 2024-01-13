import '../schema.dart';
import '../types/typed_mixin.dart';
import '../xml_extensions.dart';

part 'enumeration.dart';
part 'minmax.dart';
part 'pattern.dart';

class Restrictions extends XsdNode with BasedMixin implements TypeDeclarer {
  const Restrictions({required super.xml, required this.parent});

  static const String xmlName = 'restriction';

  final NamedMixin parent;

  @override
  String get name => '${parent.name}-restriction';

  List<RestrictionValueChoice> get values {
    return xml.childElements.map<RestrictionValueChoice>((e) {
      var element = xml.findChildElement(Enumeration.xmlName);
      if (element != null) {
        return EnumeratedRestrictionValue(xml: element);
      }
      element = xml.findChildElement(MinLength.xmlName);
      if (element != null) {
        return MinLengthRestrictionValue(xml: element);
      }
      element = xml.findChildElement(MinInclusive.xmlName);
      if (element != null) {
        return MinInclusiveRestrictionValue(xml: element);
      }
      element = xml.findChildElement(MinExclusive.xmlName);
      if (element != null) {
        return MinExclusiveRestrictionValue(xml: element);
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

  @override
  Iterable<XsdType> get declaredTypes {
    print('getting types from restriction');
    return base.declaredSubTypes;
  }
}

sealed class Restriction {}

mixin RestrictionOwnerMixin implements NamedMixin, XmlOwner {
  Restrictions get restriction {
    return Restrictions(
      xml: xml.mustFindChildElement(Restrictions.xmlName),
      parent: this,
    );
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

class MinExclusiveRestrictionValue extends XsdNode
    with MinExclusiveMixin
    implements RestrictionValueChoice {
  const MinExclusiveRestrictionValue({required super.xml});
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

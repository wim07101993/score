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
      return switch (e.name.local) {
        Enumeration.xmlName => EnumeratedRestrictionValue(xml: e),
        MinLength.xmlName => MinLengthRestrictionValue(xml: e),
        MinExclusive.xmlName => MinExclusiveRestrictionValue(xml: e),
        MinInclusive.xmlName => MinInclusiveRestrictionValue(xml: e),
        MaxInclusive.xmlName => MaxInclusiveRestrictionValue(xml: e),
        PatternRestriction.xmlName => PatternRestrictionValue(xml: e),
        String() => throw Exception('unknown restriction element found $e'),
      } as RestrictionValueChoice;
    }).toList(growable: false);
  }

  @override
  Iterable<XsdType> get declaredTypes => base.declaredSubTypes;
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

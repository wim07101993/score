import '../schema.dart';
import '../types/reference.dart';
import 'attribute.dart';

late AttributeGroup Function(String xmlName) resolveAttributeGroup;

class AttributeGroup extends XsdNode with NamedMixin, AttributesOwnerMixin {
  const AttributeGroup({required super.xml});

  static const String xmlName = 'attributeGroup';
}

class AttributeGroupReference extends XsdNode
    with ReferenceMixin<AttributeGroup>
    implements AttributeGroup {
  AttributeGroupReference({required super.xml});

  @override
  Iterable<Attribute> get attributes => refersTo.attributes;

  @override
  Iterable<AttributeGroup> get attributeGroups => refersTo.attributeGroups;

  @override
  String get name => reference;

  @override
  AttributeGroup get refersTo => resolveAttributeGroup(reference);
}

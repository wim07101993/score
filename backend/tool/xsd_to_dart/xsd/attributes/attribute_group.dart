import '../schema.dart';
import '../types/reference.dart';
import '../types/typed_mixin.dart';
import 'attribute.dart';

late AttributeGroup Function(String xmlName) resolveAttributeGroup;

class AttributeGroup extends XsdNode
    with NamedMixin, AttributesOwnerMixin
    implements TypeDeclarer {
  const AttributeGroup({required super.xml});

  static const String xmlName = 'attributeGroup';

  @override
  Iterable<XsdType> get declaredTypes sync* {
    print('getting types from attribute-group $name');
    yield* attributes.expand((attribute) => attribute.declaredTypes);
    yield* attributeGroups.expand((group) => group.declaredTypes);
  }
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

  @override
  Iterable<XsdType> get declaredTypes => const [];
}

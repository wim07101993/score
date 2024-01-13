import '../xsd/attributes/attribute.dart';
import '../xsd/attributes/attribute_group.dart';

extension AttributeGroupExtensions on AttributeGroup {
  Iterable<Attribute> get allAttributes sync* {
    yield* attributes;
    yield* attributeGroups.expand((group) => group.allAttributes);
  }
}

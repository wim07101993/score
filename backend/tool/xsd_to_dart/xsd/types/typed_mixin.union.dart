part of 'typed_mixin.dart';

class Union extends XsdType {
  const Union({
    required this.name,
    required this.simpleTypes,
    required this.memberTypes,
  });

  factory Union.fromXml({
    required XmlElement xml,
    required String parentName,
  }) {
    final List<TypeReference> memberTypes = [];
    final List<SimpleType> simpleTypes = [];
    final name = '${parentName}_Union';

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'memberTypes':
          memberTypes.add(TypeReference(name: attribute.value));
        default:
          throw Exception(
            'unknown union attribute ${attribute.name.local}',
          );
      }
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case SimpleType.xmlName:
          simpleTypes.add(SimpleType.fromXml(xml: child, parentName: name));
        default:
          throw Exception('unknown union element ${child.name.local}');
      }
    }

    return Union(
      name: name,
      simpleTypes: simpleTypes,
      memberTypes: memberTypes,
    );
  }

  static const String xmlName = 'union';

  final List<TypeReference> memberTypes;
  final List<SimpleType> simpleTypes;
  @override
  final String name;

  Iterable<XsdType> get declaredTypes sync* {
    yield* simpleTypes;
  }
}

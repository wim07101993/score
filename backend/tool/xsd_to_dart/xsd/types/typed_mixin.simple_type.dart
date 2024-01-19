part of 'typed_mixin.dart';

class SimpleType extends XsdType {
  const SimpleType({
    required this.name,
    required this.annotation,
    required this.restrictions,
    required this.union,
  });
  factory SimpleType.fromXml({
    required XmlElement xml,
    required String parentName,
  }) {
    String? name;
    Annotation? annotation;
    Restrictions? restrictions;
    Union? union;

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'name':
          name = attribute.value;
        default:
          throw Exception(
            'unknown simpleType attribute ${attribute.name.local}',
          );
      }
    }

    name ??= '${parentName}_Type';

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Annotation.xmlName:
          annotation = Annotation.fromXml(child);
        case Restrictions.xmlName:
          restrictions = Restrictions.fromXml(child);
        case Union.xmlName:
          union = Union.fromXml(xml: child, parentName: name);
        default:
          throw Exception('unknown simpleType element ${child.name.local}');
      }
    }

    return SimpleType(
      name: name,
      annotation: annotation,
      restrictions: restrictions,
      union: union,
    );
  }

  static const String xmlName = 'simpleType';

  @override
  final String name;
  final Annotation? annotation;
  final Restrictions? restrictions;
  final Union? union;

  Iterable<XsdType> get declaredTypes sync* {
    final unionTypes = union?.declaredTypes;
    if (unionTypes != null) {
      yield* unionTypes;
    }
  }
}

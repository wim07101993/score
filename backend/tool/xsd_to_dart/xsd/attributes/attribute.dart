import 'package:xml/xml.dart';

import '../schema.dart';
import '../types/typed_mixin.dart';

late Attribute Function(String xmlName) resolveAttribute;

class Attribute implements TypeDeclarer {
  const Attribute({
    required this.name,
    required this.type,
    this.fixed,
    this.defaultValue,
    this.use,
  });

  factory Attribute.fromXml(XmlElement xml) {
    String? name;
    TypeReference? type;
    String? use;
    String? defaultValue;
    String? fixed;

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'name':
          name = attribute.value;
        case 'type':
          type = TypeReference(name: attribute.value);
        case 'ref':
          name = attribute.value.split(':').last;
          type = const TypeReference(name: 'string');
        case 'use':
          use = attribute.value;
        case 'default':
          defaultValue = attribute.value;
        case 'fixed':
          fixed = attribute.value;
        default:
          throw Exception(
            'unknown attribute attribute ${attribute.name.local}',
          );
      }
    }

    if (name == null) {
      throw Exception('no name for attribute $xml');
    }
    if (type == null) {
      throw Exception('no type for attribute $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        default:
          throw Exception('unknown attribute element ${child.name.local}');
      }
    }

    return Attribute(
      name: name,
      type: type,
      use: use,
      defaultValue: defaultValue,
      fixed: fixed,
    );
  }

  static const String xmlName = 'attribute';

  final String name;
  final TypeReference type;
  final String? use;
  final String? defaultValue;
  final String? fixed;

  @override
  Iterable<XsdType> get declaredTypes sync* {}
}

import 'package:xml/xml.dart';

import '../types/typed_mixin.dart';
import 'enumeration.dart';

class Restrictions {
  const Restrictions({
    required this.values,
    required this.base,
    required this.enumerations,
  });

  factory Restrictions.fromXml(XmlElement xml) {
    TypeReference? base;
    final values = <Restriction>[];
    final enumerations = <Enumeration>[];

    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'base':
          base = TypeReference(name: attribute.value);
        default:
          throw Exception(
            'unknown restriction attribute ${attribute.name.local}',
          );
      }
    }

    if (base == null) {
      throw Exception('no base in restrictions $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case 'enumeration':
          enumerations.add(Enumeration.fromXml(child));
        default:
          values.add(Restriction.fromXml(child));
      }
    }

    return Restrictions(
      values: values,
      base: base,
      enumerations: enumerations,
    );
  }

  static const String xmlName = 'restriction';

  final List<Enumeration> enumerations;
  final List<Restriction> values;
  final TypeReference base;
}

class Restriction {
  const Restriction({
    required this.type,
    required this.value,
  });

  factory Restriction.fromXml(XmlElement xml) {
    final type = xml.name.local;
    String? value;
    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'value':
          value = attribute.value;
        default:
          throw Exception(
            'unknown $type attribute ${attribute.name.local}',
          );
      }
    }

    if (value == null) {
      throw Exception('no value for $type $xml');
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        default:
          throw Exception('unknown $type element ${child.name.local}');
      }
    }

    return Restriction(type: type, value: value);
  }

  final String value;
  final String type;
}

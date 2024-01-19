import 'package:xml/xml.dart';

import 'annotation.dart';
import 'attributes/attribute_group.dart';
import 'elements/group.dart';
import 'types/typed_mixin.dart';
import 'xml_extensions.dart';

class Schema implements TypeDeclarer, NamedMixin {
  Schema({
    required this.xml,
  }) {
    for (final attribute in xml.attributes) {
      switch (attribute.name.local) {
        case 'xs':
        case 'xlink':
        case 'elementFormDefault':
        case 'attributeFormDefault':
          // ignore xs, xlink, elementFormDefault, attributeFormDefault
          break;
        default:
          throw Exception(
            'unknown simpleType attribute ${attribute.name.local}',
          );
      }
    }

    for (final child in xml.childElements) {
      switch (child.name.local) {
        case Annotation.xmlName:
          annotations.add(Annotation.fromXml(child));
        case SimpleType.xmlName:
          simpleTypes.add(SimpleType.fromXml(xml: child, parentName: ''));
        case ComplexType.xmlName:
          complexTypes.add(ComplexType.fromXml(child));
        case AttributeGroup.xmlName:
          attributeGroups.add(AttributeGroup.fromXml(child));
        case Group.xmlName:
          groups.add(Group.fromXml(child));
        case 'import':
          // ignore imports
          break;
        case 'element':
          // TODO handle elements
          break;
        default:
          throw Exception('unknown schema element ${child.name.local}');
      }
    }
  }

  @override
  final XmlElement xml;

  @override
  String get name {
    throw Exception('All types under schema should have a name');
  }

  final List<Annotation> annotations = [];
  final List<SimpleType> simpleTypes = [];
  final List<ComplexType> complexTypes = [];
  final List<AttributeGroup> attributeGroups = [];
  final List<Group> groups = [];

  @override
  Iterable<XsdType> get declaredTypes sync* {
    yield* simpleTypes;
    yield* complexTypes;
  }
}

abstract class Named {
  String get name;
}

mixin NamedMixin implements XmlOwner, Named {
  static const String nameAttributeName = 'name';
  @override
  String get name => xml.mustGetAttribute(nameAttributeName);
}

mixin ValueOwnerMixin implements XmlOwner {
  static const String valueAttributeName = 'value';
  String get value => xml.mustGetAttribute(valueAttributeName);
}

mixin IdNodeMixin implements XmlOwner {
  static const String idAttributeName = 'id';
  String? get id => xml.getAttribute(idAttributeName);
}

mixin OccurrenceMixin implements XmlOwner {
  bool get isNullable => minOccurs == '0';
  String get minOccurs => xml.getAttribute('minOccurs') ?? '1';
  String get maxOccurs => xml.getAttribute('maxOccurs') ?? '1';
}

abstract class XmlOwner {
  XmlElement get xml;
}

abstract class TypeDeclarer {
  Iterable<XsdType> get declaredTypes;
}

abstract class XsdNode implements XmlOwner {
  const XsdNode({required this.xml});

  @override
  final XmlElement xml;

  Annotation? get annotation {
    final element = xml.findChildElement(Annotation.xmlName);
    return element == null ? null : Annotation.fromXml(element);
  }
}

enum XmlDataTypes { string, decimal, integer, boolean, date, time }

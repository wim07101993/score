import 'package:xml/xml.dart';

import 'annotation.dart';
import 'attributes/attribute_group.dart';
import 'elements/group.dart';
import 'types/typed_mixin.dart';

class Schema {
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
          complexTypes.add(ComplexType.fromXml(xml: child, parentName: ''));
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

  final XmlElement xml;

  final List<Annotation> annotations = [];
  final List<SimpleType> simpleTypes = [];
  final List<ComplexType> complexTypes = [];
  final List<AttributeGroup> attributeGroups = [];
  final List<Group> groups = [];

  Iterable<XsdType> get declaredTypes sync* {
    yield* simpleTypes;
    yield* complexTypes;
  }
}

enum XmlDataTypes { string, decimal, integer, boolean, date, time }

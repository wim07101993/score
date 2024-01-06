import 'package:xml/xml.dart';

import 'annotation.dart';
import 'attributes/attribute.dart';
import 'types/typed_mixin.dart';
import 'xml_extensions.dart';

class Schema
    with
        SimpleTypesOwnerMixin,
        ComplexTypesOwnerMixin,
        AttributesOwnerMixin,
        MultiAnnotatedMixin {
  const Schema({required this.xml});

  @override
  final XmlElement xml;
}

mixin NamedMixin implements XmlOwner {
  String get name => xml.mustGetAttribute('name');
}

mixin ValueOwnerMixin implements XmlOwner {
  String get value => xml.mustGetAttribute('value');
}

mixin IdNodeMixin implements XmlOwner {
  String? get id => xml.getAttribute('id');
}

mixin BasedMixin implements XmlOwner {
  String get base => xml.mustGetAttribute('base');
}

mixin OccurrenceMixin implements XmlOwner {
  bool get isNullable => minOccurs == '0';
  String get minOccurs => xml.getAttribute('minOccurs') ?? '1';
  String get maxOccurs => xml.getAttribute('maxOccurs') ?? '1';
}

abstract class XmlOwner {
  XmlElement get xml;
}

class XsdNode implements XmlOwner {
  const XsdNode({required this.xml});

  @override
  final XmlElement xml;

  Annotation? get annotation {
    final element = xml.findChildElement(Annotation.xmlName);
    return element == null ? null : Annotation(xml: element);
  }
}

enum XmlDataTypes { string, decimal, integer, boolean, date, time }

import '../schema.dart';
import '../types/reference.dart';
import '../types/typed_mixin.dart';
import 'attribute.dart';

class AttributeReference extends XsdNode
    with ReferenceMixin<Attribute>
    implements Attribute {
  const AttributeReference({required super.xml});

  @override
  String? get defaultValue => xml.getAttribute('default');

  @override
  String? get fixedValue => xml.getAttribute('fixed');

  @override
  bool get isRequired => xml.getAttribute('use') == 'required';

  @override
  Attribute get refersTo => resolveAttribute(reference);

  @override
  String get name => reference;

  @override
  XsdType get type => refersTo.type;

  @override
  String get typeXmlName => refersTo.typeXmlName;
}

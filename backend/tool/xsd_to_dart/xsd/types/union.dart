import '../schema.dart';
import '../xml_extensions.dart';
import 'typed_mixin.dart';

class Union extends XsdNode with SimpleTypesOwnerMixin, ComplexTypesOwnerMixin {
  Union({required super.xml});

  static const String xmlName = 'union';

  List<String> get memberTypes {
    return [
      ...xml.getAttribute('memberTypes')?.split(' ') ?? const [],
      ...simpleTypes.map((type) => type.name),
    ];
  }
}

mixin UnionOwnerMixin implements XmlOwner {
  Union get union => Union(xml: xml.mustFindChildElement('union'));
}

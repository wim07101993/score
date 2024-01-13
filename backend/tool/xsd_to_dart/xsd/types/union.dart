import '../schema.dart';
import '../xml_extensions.dart';
import 'typed_mixin.dart';

class Union extends XsdNode
    with SimpleTypesOwnerMixin, ComplexTypesOwnerMixin
    implements TypeDeclarer {
  Union({
    required super.xml,
    required this.parent,
  });

  static const String xmlName = 'union';

  final NamedMixin parent;

  List<String> get memberTypes {
    return [
      ...xml.getAttribute('memberTypes')?.split(' ') ?? const [],
      ...simpleTypes.map((type) => type.name),
    ];
  }

  @override
  Iterable<XsdType> get declaredTypes {
    print('getting types from union');
    return simpleTypes.expand((simpleType) => simpleType.declaredTypes);
  }

  @override
  String get name => '${parent.name}-choice';
}

mixin UnionOwnerMixin implements NamedMixin, XmlOwner {
  Union get union {
    return Union(
      xml: xml.mustFindChildElement('union'),
      parent: this,
    );
  }
}

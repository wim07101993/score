part of 'typed_mixin.dart';

class Union extends XsdNode
    with SimpleTypesOwnerMixin, ComplexTypesOwnerMixin
    implements XsdType, TypeDeclarer {
  Union({
    required super.xml,
    required this.parent,
  });

  static const String xmlName = 'union';

  final NamedMixin parent;

  List<String> get memberTypes {
    return xml.getAttribute('memberTypes')?.split(' ') ?? const [];
  }

  @override
  Iterable<XsdType> get declaredTypes sync* {
    yield* simpleTypes;
    yield* simpleTypes.expand((simpleType) => simpleType.declaredTypes);
  }

  @override
  String get name => '${parent.name}-union';
}

mixin UnionOwnerMixin implements NamedMixin, XmlOwner {
  Union get union {
    return Union(
      xml: xml.mustFindChildElement('union'),
      parent: this,
    );
  }
}

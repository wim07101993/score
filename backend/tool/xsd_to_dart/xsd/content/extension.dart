import '../attributes/attribute.dart';
import '../schema.dart';
import '../types/typed_mixin.dart';
import '../xml_extensions.dart';

class Extension extends XsdNode
    with BasedMixin, AttributesOwnerMixin
    implements TypeDeclarer {
  const Extension({
    required super.xml,
    required this.parent,
  });

  static const String xmlName = 'extension';

  final NamedMixin parent;

  @override
  Iterable<XsdType> get declaredTypes sync* {
    yield* base.declaredSubTypes;
    yield* attributes.expand((attribute) => attribute.declaredTypes);
    yield* attributeGroups.expand((group) => group.declaredTypes);
  }

  @override
  String get name => '${parent.name}-extension';
}

mixin ExtensionOwnerMixin implements XmlOwner, NamedMixin {
  Extension? get extension {
    final element = xml.findChildElement(Extension.xmlName);
    return element == null ? null : Extension(xml: element, parent: this);
  }
}

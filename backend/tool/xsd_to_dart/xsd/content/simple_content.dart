import '../schema.dart';
import '../types/typed_mixin.dart';
import '../xml_extensions.dart';
import 'extension.dart';

class SimpleContent extends XsdNode
    with ExtensionOwnerMixin
    implements TypeDeclarer {
  const SimpleContent({
    required super.xml,
    required this.parent,
  });

  final NamedMixin parent;

  @override
  Iterable<XsdType> get declaredTypes => extension?.declaredTypes ?? const [];

  @override
  String get name => '${parent.name}-simple-content';
}

mixin SimpleContentOwnerMixin implements XmlOwner, NamedMixin {
  SimpleContent? get simpleContent {
    final element = xml.findChildElement('simpleContent');
    return element == null ? null : SimpleContent(xml: element, parent: this);
  }
}

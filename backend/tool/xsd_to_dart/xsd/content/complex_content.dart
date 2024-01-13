import '../schema.dart';
import '../types/typed_mixin.dart';
import '../xml_extensions.dart';
import 'extension.dart';

class ComplexContent extends XsdNode
    with ExtensionOwnerMixin
    implements TypeDeclarer {
  ComplexContent({required super.xml, required this.parent});

  static const String xmlName = 'complexContent';

  final NamedMixin parent;

  @override
  String get name => '${parent.name}-complex-content';

  @override
  Iterable<XsdType> get declaredTypes {
    print('getting types from complex content');
    return extension?.declaredTypes ?? const [];
  }
}

mixin ComplexContentOwner implements XmlOwner, NamedMixin {
  ComplexContent? get complexContent {
    final child = xml.findChildElement(ComplexContent.xmlName);
    return child == null ? null : ComplexContent(xml: child, parent: this);
  }
}

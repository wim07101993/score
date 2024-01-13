import '../schema.dart';
import '../types/typed_mixin.dart';
import 'element.dart';

class Sequence extends XsdNode
    with OccurrenceMixin, ElementsOwnerMixin
    implements TypeDeclarer {
  const Sequence({required super.xml});

  static const String xmlName = 'sequence';

  @override
  Iterable<XsdType> get declaredTypes {
    return elements.expand((element) => element.declaredTypes);
  }
}

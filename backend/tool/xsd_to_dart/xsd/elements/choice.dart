import '../schema.dart';
import '../types/typed_mixin.dart';
import 'element.dart';

class Choice extends XsdNode
    with OccurrenceMixin, ElementsOwnerMixin
    implements TypeDeclarer {
  const Choice({required super.xml});

  static const String xmlName = 'choice';

  @override
  Iterable<XsdType> get declaredTypes {
    return elements.expand((element) => element.declaredTypes);
  }
}

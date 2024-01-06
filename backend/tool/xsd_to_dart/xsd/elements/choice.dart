import '../schema.dart';
import 'element.dart';

class Choice extends XsdNode with OccurrenceMixin, ElementsOwnerMixin {
  const Choice({required super.xml});

  static const String xmlName = 'choice';
}

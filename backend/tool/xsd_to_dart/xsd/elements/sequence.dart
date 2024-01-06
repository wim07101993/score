import '../schema.dart';
import 'element.dart';

class Sequence extends XsdNode with OccurrenceMixin, ElementsOwnerMixin {
  const Sequence({required super.xml});

  static const String xmlName = 'sequence';
}

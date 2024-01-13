import '../annotation.dart';
import '../schema.dart';
import '../types/reference.dart';
import '../types/typed_mixin.dart';
import 'choice.dart';
import 'element.dart';
import 'sequence.dart';

late Group Function(String xmlName) resolveGroup;

class Group extends XsdNode
    with NamedMixin, OccurrenceMixin, ElementsOwnerMixin
    implements TypeDeclarer {
  const Group({required super.xml});

  static const String xmlName = 'group';

  @override
  Iterable<XsdType> get declaredTypes {
    return elements.expand((element) => element.declaredTypes);
  }
}

class GroupReference extends XsdNode
    with ReferenceMixin<Group>
    implements Group {
  const GroupReference({required super.xml});

  @override
  Annotation? get annotation => refersTo.annotation;

  @override
  Group get refersTo => resolveGroup(reference);

  @override
  bool get isNullable => refersTo.isNullable;

  @override
  String get maxOccurs => refersTo.maxOccurs;

  @override
  String get minOccurs => refersTo.minOccurs;

  @override
  Iterable<Choice> get choices => refersTo.choices;

  @override
  Iterable<Element> get elements => refersTo.elements;

  @override
  Iterable<Group> get groups => refersTo.groups;

  @override
  Sequence? get sequence => refersTo.sequence;

  @override
  Iterable<XsdType> get declaredTypes => const [];

  @override
  String get name => reference;
}

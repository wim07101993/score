import '../xsd/elements/element.dart';
import '../xsd/elements/group.dart';

extension GroupExtensions on Group {
  Iterable<Element> get allElements sync* {
    yield* elements;
    yield* groups.expand((group) => group.allElements);
  }
}

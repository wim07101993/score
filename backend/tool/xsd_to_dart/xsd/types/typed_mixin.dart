import 'package:xml/xml.dart';

import '../../code/string_extensions.dart';
import '../annotation.dart';
import '../attributes/attribute.dart';
import '../attributes/attribute_group.dart';
import '../content/complex_content.dart';
import '../content/simple_content.dart';
import '../elements/choice.dart';
import '../elements/group.dart';
import '../elements/sequence.dart';
import '../restriction/restriction.dart';

part 'typed_mixin.complex_type.dart';
part 'typed_mixin.simple_type.dart';
part 'typed_mixin.union.dart';

sealed class XsdType {
  const XsdType();

  String get name;
  String get dartTypeName => name.toDartTypeName();
}

class TypeReference extends XsdType {
  const TypeReference({
    required this.name,
  });

  @override
  final String name;
}

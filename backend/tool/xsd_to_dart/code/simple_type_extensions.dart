import 'dart:io';

import '../xsd/restriction/restriction.dart';
import '../xsd/types/typed_mixin.dart';
import 'alias.dart';
import 'code.dart';
import 'enum.dart';
import 'string_extensions.dart';
import 'xsd_node_extension.dart';

extension SimpleTypeExtensions on SimpleType {
  void writeAsCode(IOSink sink) {
    final value = this.value;
    switch (value) {
      case SimpleTypeValueRestriction():
        final restrictions = value.restriction.values;
        if (restrictions.firstOrNull is EnumeratedRestrictionValue) {
          writeEnum(
            sink,
            docs: docs,
            name: name,
            values: restrictions.enumerations
                .map((e) => (e.docs, e.value))
                .toList(growable: false),
          );
        } else {
          writeAlias(
            sink,
            name: name,
            baseType: value.restriction.base.name.toDartTypeName(),
            minLength: restrictions.minLength?.value,
            minExclusive: restrictions.minExclusive?.value,
            minInclusive: restrictions.minInclusive?.value,
            maxInclusive: restrictions.maxInclusive?.value,
            pattern: restrictions.pattern?.value,
            docs: docs,
          );
        }
      case SimpleTypeValueUnion():
        writeUnion(
          sink,
          name: name,
          types: [
            ...value.union.memberTypes,
            ...value.union.declaredTypes.map((type) => type.name),
          ],
          docs: docs,
        );
    }
  }
}

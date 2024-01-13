import 'dart:io';

import '../xsd/types/typed_mixin.dart';

extension UnionTypeExtension on Union {
  void writeAsCode(IOSink sink) {
    // writeUnion(
    //   sink,
    //   name: name.toDartTypeName(),
    //   types: memberTypes
    //       .map((type) => type.toDartTypeName())
    //       .toList(growable: false),
    //   docs: docs,
    // );
  }
}

import 'dart:io';

import '../xsd/types/typed_mixin.dart';
import 'constructor.dart';
import 'documentation.dart';
import 'parameter.dart';
import 'property.dart';

part 'class.dart';

late DartType Function(String typeName) resolveDartType;

sealed class DartType {
  String get name;
}

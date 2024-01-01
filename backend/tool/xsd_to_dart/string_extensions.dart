import 'package:dart_casing/dart_casing.dart';

extension XsdStringExtensions on String {
  String toDartTypeName() {
    return switch (this) {
      'xs:integer' => 'int',
      'xs:positiveInteger' => 'int',
      'xs:nonNegativeInteger' => 'int',
      'xs:decimal' => 'double',
      'xs:token' => 'String',
      'xs:string' => 'String',
      'xs:NMTOKEN' => 'String',
      'xs:ID' => 'String',
      'xs:date' => 'DateTime',
      String() => Casing.pascalCase(this),
    };
  }
}

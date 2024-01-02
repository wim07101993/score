import 'package:dart_casing/dart_casing.dart';

extension XsdStringExtensions on String {
  String toDartTypeName() {
    return switch (this) {
      'string' => 'GuitarString',
      'xs:integer' => 'int',
      'xs:positiveInteger' => 'int',
      'xs:nonNegativeInteger' => 'int',
      'xs:decimal' => 'double',
      'xs:token' => 'String',
      'xs:string' => 'String',
      'xs:NMTOKEN' => 'String',
      'xs:ID' => 'String',
      'xs:anyURI' => 'String',
      'xs:IDREF' => 'String',
      'xml:lang' => 'String',
      'xml:space' => 'String',
      'xlink:href' => 'String',
      'xlink:type' => 'String',
      'xlink:role' => 'String',
      'xlink:title' => 'String',
      'xlink:show' => 'String',
      'xlink:actuate' => 'String',
      'xs:date' => 'DateTime',
      String() => Casing.pascalCase(this),
    };
  }
}

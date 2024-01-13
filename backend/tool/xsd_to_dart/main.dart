import 'dart:io';

import 'package:path/path.dart';
import 'package:xml/xml.dart';

import 'code/complex_type_extensions.dart';
import 'code/simple_type_extensions.dart';
import 'code/union_type_extensions.dart';
import 'xsd/schema.dart' as xsd;
import 'xsd/types/typed_mixin.dart' as xsd;

final sink = File(join('lib', 'src', 'musicxml', 'models.g.dart')).openWrite();

Future<void> main() async {
  final schema = await File(join('doc', 'musicxml', 'musicxml.xsd'))
      .readAsString()
      .then(XmlDocument.parse)
      .then((xml) => xsd.Schema(xml: xml.rootElement));

  final types = schema.declaredTypes;
  for (final type in types) {
    switch (type) {
      case xsd.TypeReference():
        continue; // references do not have to be declared
      case xsd.ComplexType():
        type.writeAsCode(sink);
      case xsd.SimpleType():
        type.writeAsCode(sink);
      case xsd.Union():
        type.writeAsCode(sink);
    }
    await sink.flush();
    sink.writeln();
  }
}

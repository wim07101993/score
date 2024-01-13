import 'dart:io';

import 'package:path/path.dart';
import 'package:xml/xml.dart';

import 'barrel_file.dart';
import 'code/complex_type_extensions.dart';
import 'code/simple_type_extensions.dart';
import 'globals.dart';
import 'xsd/schema.dart' as xsd;
import 'xsd/types/typed_mixin.dart' as xsd;

Future<void> main() async {
  await ensureBarrelFileImported();

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
        type.writeAsCode(classesSink);
        await aliasesSink.flush();
      case xsd.SimpleType():
        type.writeAsCode(aliasesSink);
        await aliasesSink.flush();
    }
  }
}

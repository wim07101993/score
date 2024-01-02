import 'dart:io';

import 'package:path/path.dart';
import 'package:xml/xml.dart';

import 'barrel_file.dart';
import 'code/code.dart';
import 'globals.dart';
import 'xsd_to_dart.dart';

Future<void> main() async {
  await ensureBarrelFileImported();

  final xsd = await File(join('doc', 'musicxml', 'musicxml.xsd'))
      .readAsString()
      .then(XmlDocument.parse);
  final types = createCodeFromXsdDoc(xsd);
  for (final type in types) {
    allTypes.add(type);

    if (type is NativeType) {
      continue;
    }

    final sink = switch (type) {
      Alias() => aliasesSink,
      Enum() => enumsSink,
      Interface() => interfacesSink,
      Union() => unionsSink,
      Class() => classesSink,
      NativeType() => throw Exception('native types should not be written'),
    };

    sink.writeln();
    type.writeTo(sink);
    await sink.flush();
  }
}

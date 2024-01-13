import 'dart:io';

import 'package:path/path.dart';

import 'globals.dart';

Future<void> ensureBarrelFileImported() async {
  const barrelFileName = 'barrel.g.dart';
  final barrelFile = File(join(modelsDirPath, barrelFileName));
  if (!await barrelFile.exists()) {
    await barrelFile.create(recursive: true);
  }
  final barrelSink = barrelFile.openWrite();
  for (final sink in [
    aliasesSink,
    classesSink,
    enumsSink,
    mixinsSink,
    unionsSink,
  ]) {
    sink
      ..writeln(
        "// ignore_for_file: unused_import, always_use_package_imports, camel_case_types",
      )
      ..writeln("import '$barrelFileName';");
  }

  barrelSink
    ..writeln("export 'package:xml/xml.dart';")
    ..writeln()
    ..writeln("export '$aliasesFileName';")
    ..writeln("export '$classesFileName';")
    ..writeln("export '$enumsFileName';")
    ..writeln("export '$unionsFileName';");

  await barrelSink.flush();
  await barrelSink.close();
}

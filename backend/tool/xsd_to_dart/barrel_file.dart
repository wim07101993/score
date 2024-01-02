import 'dart:io';

import 'package:path/path.dart';

import 'globals.dart';

Future<void> ensureBarrelFileImported() async {
  const barrelFileName = 'barrel.g.dart';
  final barrelFile = File(join(modelsDirPath, barrelFileName));
  final barrelSink = barrelFile.openWrite();
  for (final sink in [
    enumsSink,
    aliasesSink,
    unionsSink,
    interfacesSink,
    classesSink,
  ]) {
    sink
      ..writeln(
        "// ignore_for_file: unused_import, always_use_package_imports, camel_case_types",
      )
      ..writeln("import '$barrelFileName';");
  }

  barrelSink
    ..writeln("export '$aliasesFileName';")
    ..writeln("export '$classesFileName';")
    ..writeln("export '$enumsFileName';")
    ..writeln("export '$interfacesFileName';")
    ..writeln("export '$unionsFileName';");

  await barrelSink.flush();
  await barrelSink.close();
}

import 'dart:io';

import 'package:path/path.dart';

import 'code/code.dart';

const enumsFileName = 'enums.g.dart';
const aliasesFileName = 'aliases.g.dart';
const unionsFileName = 'unions.g.dart';
const interfacesFileName = 'interfaces.g.dart';
const classesFileName = 'classes.g.dart';

final modelsDirPath = join('lib', 'src', 'musicxml', 'models');
final enumsSink = File(join(modelsDirPath, enumsFileName)).openWrite();
final aliasesSink = File(join(modelsDirPath, aliasesFileName)).openWrite();
final unionsSink = File(join(modelsDirPath, unionsFileName)).openWrite();
final interfacesSink =
    File(join(modelsDirPath, interfacesFileName)).openWrite();
final classesSink = File(join(modelsDirPath, classesFileName)).openWrite();

final allTypes = <Type>[
  const Int(),
  const Double(),
  const StringType(),
];

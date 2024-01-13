import 'dart:io';

import 'package:path/path.dart';

const aliasesFileName = 'aliases.g.dart';
const classesFileName = 'classes.g.dart';
const enumsFileName = 'enums.g.dart';
const mixinsFileName = 'mixins.g.dart';
const unionsFileName = 'unions.g.dart';

final modelsDirPath = join('lib', 'src', 'musicxml', 'models');

final aliasesSink = File(join(modelsDirPath, aliasesFileName)).openWrite();
final classesSink = File(join(modelsDirPath, classesFileName)).openWrite();
final enumsSink = File(join(modelsDirPath, enumsFileName)).openWrite();
final mixinsSink = File(join(modelsDirPath, mixinsFileName)).openWrite();
final unionsSink = File(join(modelsDirPath, unionsFileName)).openWrite();

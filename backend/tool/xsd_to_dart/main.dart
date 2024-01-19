import 'dart:io';

import 'package:path/path.dart';
import 'package:xml/xml.dart';

import 'code/group_extensions.dart';
import 'code/type_extensions.dart';
import 'xsd/attributes/attribute_group.dart';
import 'xsd/elements/group.dart';
import 'xsd/schema.dart' as xsd;

const String barrelFileName = 'models.g.dart';
const String interfacesFileName = 'interfaces.g.dart';
const String typesFileName = 'types.g.dart';
final modelsDirectory = join('lib', 'src', 'musicxml', 'models');

Future<void> main() async {
  final schema = await File(join('doc', 'musicxml', 'musicxml.xsd'))
      .readAsString()
      .then(XmlDocument.parse)
      .then((xml) => xsd.Schema(xml: xml.rootElement));

  resolveAttributeGroup = (xmlName) {
    return schema.attributeGroups
        .firstWhere((attributeGroup) => attributeGroup.name == xmlName);
  };
  resolveGroup = (xmlName) {
    return schema.groups.firstWhere((group) => group.name == xmlName);
  };

  final dir = Directory(modelsDirectory);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  await Future.wait([
    writeBarrelFile(),
    writeTypes(schema),
    writeGroups(schema),
  ]);
}

Future<void> writeBarrelFile() async {
  final sink = File(join(modelsDirectory, barrelFileName)).openWrite();
  try {
    sink
      ..writeln("part '$interfacesFileName';")
      ..writeln("part '$typesFileName';");
    await sink.flush();
  } finally {
    sink.close();
  }
}

Future<void> writeTypes(xsd.Schema schema) async {
  final sink = File(join(modelsDirectory, typesFileName)).openWrite();
  sink
    ..writeln("part of '$barrelFileName';")
    ..writeln();

  try {
    for (final type in schema.simpleTypes) {
      type.writeAsCode(sink);
      sink.writeln();
      await sink.flush();
    }
    for (final type in schema.complexTypes) {
      type.writeAsCode(sink);
      sink.writeln();
      await sink.flush();
    }
  } finally {
    await sink.close();
  }
}

Future<void> writeGroups(xsd.Schema schema) async {
  final sink = File(join(modelsDirectory, interfacesFileName)).openWrite();
  sink
    ..writeln("part of  '$barrelFileName';")
    ..writeln();

  try {
    for (final attributeGroup in schema.attributeGroups) {
      attributeGroup.writeAsCode(sink);
      sink.writeln();
      await sink.flush();
    }

    for (final elementGroup in schema.groups) {
      elementGroup.writeAsCode(sink);
      sink.writeln();
      await sink.flush();
    }
  } finally {
    await sink.close();
  }
}

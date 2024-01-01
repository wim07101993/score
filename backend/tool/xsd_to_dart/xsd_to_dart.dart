import 'dart:io';

import 'package:path/path.dart';
import 'package:xml/xml.dart';

import 'code/code.dart';
import 'xml_element_extensions.dart';

const enumsFileName = 'enums.g.dart';
const aliasesFileName = 'aliases.g.dart';
const unionsFileName = 'unions.g.dart';
const interfacesFileName = 'interfaces.g.dart';

final modelsDirPath = join('lib', 'src', 'musicxml', 'models');
final xsdFile = File(join('doc', 'musicxml', 'musicxml.xsd'));
final enumsSink = File(join(modelsDirPath, enumsFileName)).openWrite();
final aliasesSink = File(join(modelsDirPath, aliasesFileName)).openWrite();
final unionsSink = File(join(modelsDirPath, unionsFileName)).openWrite();
final interfacesSink =
    File(join(modelsDirPath, interfacesFileName)).openWrite();

Future<void> main() async {
  final xsd = await xsdFile.readAsString().then(XmlDocument.parse);

  await ensureBarrelFileImported();

  final typeItems =
      xsd.rootElement.childElements.expand(createCodeFromXmlElement);
  for (final type in typeItems) {
    final sink = switch (type) {
      Alias() => aliasesSink,
      Enum() => enumsSink,
      Interface() => interfacesSink,
      Union() => unionsSink,
    };

    type.writeTo(sink);
    await sink.flush();
  }
}

Iterable<Type> createCodeFromXmlElement(XmlElement element) sync* {
  switch (element.name.local) {
    case 'simpleType':
      yield createSimpleType(element);
    case 'complexType':
    // TODO
    case 'attributeGroup':
      yield element.attributeGroupToInterface();
  }
}

Type createSimpleType(XmlElement element) {
  final typeName = element.typeName;
  final restrictionElement = element.restrictionElement;
  if (restrictionElement != null) {
    switch (restrictionElement.mustGetAttribute('base', typeName)) {
      case 'xs:token':
      case 'xs:string':
        if (element.enumerationElements.isNotEmpty) {
          return element.simpleTypeToEnum();
        } else {
          return element.simpleTypeToAlias();
        }

      default:
        return element.simpleTypeToAlias();
    }
  }

  if (element.unionElement != null) {
    return element.simpleTypeToUnion();
  }

  throw Exception("don't know what to do with element $typeName:\n$element");
}

Future<void> ensureBarrelFileImported() async {
  const barrelFileName = 'barrel.g.dart';
  final barrelFile = File(join(modelsDirPath, barrelFileName));
  final barrelSink = barrelFile.openWrite();
  for (final sink in [
    enumsSink,
    aliasesSink,
    unionsSink,
    interfacesSink,
  ]) {
    sink
      ..writeln("// ignore: unused_import, always_use_package_imports")
      ..writeln("import '$barrelFileName';")
      ..writeln();
  }

  barrelSink
    ..writeln("export '$aliasesFileName';")
    ..writeln("export '$enumsFileName';")
    ..writeln("export '$unionsFileName';");

  await barrelSink.flush();
  await barrelSink.close();
}

import 'dart:io';

import 'package:path/path.dart';
import 'package:xml/xml.dart';

import 'code/code.dart';
import 'complex_type_xml_element_extensions.dart';
import 'simple_type_xml_element_extensions.dart';
import 'xml_element_extensions.dart';

const enumsFileName = 'enums.g.dart';
const aliasesFileName = 'aliases.g.dart';
const unionsFileName = 'unions.g.dart';
const interfacesFileName = 'interfaces.g.dart';
const classesFileName = 'classes.g.dart';

final modelsDirPath = join('lib', 'src', 'musicxml', 'models');
final xsdFile = File(join('doc', 'musicxml', 'musicxml.xsd'));
final enumsSink = File(join(modelsDirPath, enumsFileName)).openWrite();
final aliasesSink = File(join(modelsDirPath, aliasesFileName)).openWrite();
final unionsSink = File(join(modelsDirPath, unionsFileName)).openWrite();
final interfacesSink =
    File(join(modelsDirPath, interfacesFileName)).openWrite();
final classesSink = File(join(modelsDirPath, classesFileName)).openWrite();

final _types = <Type>[
  NativeType.int(),
  NativeType.double(),
  NativeType.string(),
];

Future<void> main() async {
  final xsd = await xsdFile.readAsString().then(XmlDocument.parse);

  await ensureBarrelFileImported();

  _types.addAll(
    xsd.rootElement.childElements
        .expand(createCodeFromXmlElement)
        .toList(growable: false),
  );
  for (final type in _types.where((type) => type is! NativeType)) {
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

Iterable<Type> createCodeFromXmlElement(XmlElement element) sync* {
  switch (element.name.local) {
    case 'simpleType':
      yield createSimpleType(element);
    case 'complexType':
      yield element.toClass();
    case 'attributeGroup':
      yield element.toInterface();
    case 'group':
      yield element.toInterface();
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
          return element.toEnum();
        } else {
          return element.toAlias();
        }

      default:
        return element.toAlias();
    }
  }

  if (element.unionElement != null) {
    return element.toUnion();
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

Interface resolveInterface(String name) {
  return _types
      .whereType<Interface>()
      .firstWhere((interface) => interface.name == name);
}

Type resolveType(String name) {
  return _types.whereType<Type>().firstWhere(
        (c) => c.name == name,
        orElse: () => throw Exception('no type with name $name'),
      );
}

import 'dart:io';

import 'package:path/path.dart';
import 'package:xml/xml.dart';

import 'code/code.dart';
import 'code_sink.dart';
import 'xml_element_extensions.dart';

const enumsFileName = 'enums.g.dart';
const aliasesFileName = 'aliases.g.dart';

final modelsDirPath = join('lib', 'src', 'musicxml', 'models');
final xsdFile = File(join('doc', 'musicxml', 'musicxml.xsd'));
final enumsFile = File(join(modelsDirPath, enumsFileName));
final aliasesFile = File(join(modelsDirPath, aliasesFileName));

Future<void> main() async {
  final xsd = await xsdFile.readAsString().then(XmlDocument.parse);
  final codeSink = CodeSink(
    enumSink: enumsFile.openWrite(),
    aliasSink: aliasesFile.openWrite(),
  );

  codeSink.enumSink
    ..writeln("// ignore: unused_import, always_use_package_imports")
    ..writeln("import '$aliasesFileName';")
    ..writeln();
  codeSink.aliasSink
    ..writeln("// ignore: unused_import, always_use_package_imports")
    ..writeln("import '$enumsFileName';")
    ..writeln();

  final codeItems =
      xsd.rootElement.childElements.expand(createCodeFromXmlElement);
  for (final code in codeItems) {
    code.writeTo(codeSink);
    await codeSink.flush();
  }
}

Iterable<Code> createCodeFromXmlElement(XmlElement element) sync* {
  switch (element.name.local) {
    case 'simpleType':
      yield createSimpleType(element);
    case 'complexType':
    // don't generate complex types since they are way to much work
  }
}

Code createSimpleType(XmlElement element) {
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

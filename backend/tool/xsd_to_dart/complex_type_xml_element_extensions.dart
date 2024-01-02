import 'package:dart_casing/dart_casing.dart';
import 'package:xml/xml.dart';

import 'code/code.dart';
import 'string_extensions.dart';
import 'xml_element_extensions.dart';
import 'xsd_xml_element_extensions.dart';

typedef TypeResolver = ComplexType Function(String typeName);

extension ComplexTypeXmlElementExtensions on XmlElement {
  Iterable<XmlElement> get choiceElements => findChildElements('choice');
  Iterable<XmlElement> get sequenceElements => findChildElements('sequence');
  Iterable<XmlElement> get groupElements => findChildElements('group');
  Iterable<XmlElement> get elementElements => findChildElements('element');
  Iterable<XmlElement> get attributeElements => findChildElements('attribute');
  Iterable<XmlElement> get attributeGroupElements =>
      findChildElements('attributeGroup');

  XmlElement? get simpleContentElement =>
      findChildElements('simpleContent').firstOrNull;
  XmlElement? get extensionElement =>
      simpleContentElement?.findChildElements('extension').firstOrNull;

  Iterable<Property> abstractProperties(String forType) sync* {
    yield* attributeElements.map((attribute) {
      final docs = attribute.documentation.toList(growable: false);
      final ref = attribute.getAttribute('ref');
      final isRequired = attribute.getAttribute('use') != 'required';
      return switch (ref) {
        String() => AbstractProperty(
            name: Casing.camelCase(ref.split(':').last),
            type: ref.toDartTypeName(),
            docs: docs,
            isNullable: isRequired,
          ),
        null => AbstractProperty(
            name: Casing.camelCase(attribute.mustGetAttribute('name', forType)),
            type: attribute.mustGetAttribute('type', forType).toDartTypeName(),
            docs: docs,
            isNullable: isRequired,
          ),
      };
    });
  }

  Iterable<Property> propertyImplementations(String forType) sync* {
    yield* attributeElements.map((attribute) {
      final docs = attribute.documentation.toList(growable: false);
      final ref = attribute.getAttribute('ref');
      final isRequired = attribute.getAttribute('use') != 'required';
      return switch (ref) {
        String() => PropertyImplementation(
            name: Casing.camelCase(ref.split(':').last),
            type: ref.toDartTypeName(),
            docs: docs,
            isNullable: isRequired,
            isOverridden: false,
          ),
        null => PropertyImplementation(
            name: Casing.camelCase(attribute.mustGetAttribute('name', forType)),
            type: attribute.mustGetAttribute('type', forType).toDartTypeName(),
            docs: docs,
            isNullable: isRequired,
            isOverridden: false,
          ),
      };
    });
    yield* elementElements.map((element) {
      final docs = element.documentation.toList(growable: false);
      final maxOccurs =
          int.tryParse(element.getAttribute('maxOccurs') ?? '') ?? 1;
      final minOccurs =
          int.tryParse(element.getAttribute('minOccurs') ?? '') ?? 1;
      final type = element.mustGetAttribute('type', forType).toDartTypeName();
      return PropertyImplementation(
        docs: docs,
        name: Casing.camelCase(element.mustGetAttribute('name', forType)),
        type: maxOccurs > 1 ? 'List<$type>' : type,
        isNullable: minOccurs == 0 && maxOccurs == 1,
        isOverridden: false,
      );
    });
  }

  Iterable<String> interfaces(String forType) {
    return attributeGroupElements.map((attributeGroup) {
      return attributeGroup.mustGetAttribute('ref', forType).toDartTypeName();
    });
  }

  Interface toInterface() {
    final typeName = this.typeName;
    return Interface(
      name: typeName,
      docs: documentation.toList(growable: false),
      properties: abstractProperties(typeName).toList(growable: false),
      interfaces: interfaces(typeName).toList(growable: false),
    );
  }

  Class toClass() {
    // TODO choice, elements, group
    final typeName = this.typeName;
    final extension = extensionElement;
    if (extension == null) {
      return Class(
        name: typeName,
        docs: documentation.toList(growable: false),
        properties: propertyImplementations(typeName).toList(growable: false),
        interfaces: interfaces(typeName).toList(growable: false),
        baseType: null,
      );
    }
    return Class(
      name: typeName,
      docs: documentation.toList(growable: false),
      properties:
          extension.propertyImplementations(typeName).toList(growable: false),
      interfaces: extension.interfaces(typeName).toList(growable: false),
      baseType: extension.mustGetAttribute('base', typeName).toDartTypeName(),
    );
  }
}

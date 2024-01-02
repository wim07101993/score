import 'package:dart_casing/dart_casing.dart';
import 'package:xml/xml.dart';

import 'code/code.dart';
import 'string_extensions.dart';
import 'type_resolvers.dart';
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
            type: resolveType(ref.toTypeName()),
            docs: docs,
            isNullable: isRequired,
          ),
        null => AbstractProperty(
            name: Casing.camelCase(attribute.mustGetAttribute('name', forType)),
            type: resolveType(
              attribute.mustGetAttribute('type', forType).toTypeName(),
            ),
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
            type: resolveType(ref.toTypeName()),
            docs: docs,
            isNullable: isRequired,
            isOverridden: false,
          ),
        null => PropertyImplementation(
            name: Casing.camelCase(attribute.mustGetAttribute('name', forType)),
            type: resolveType(
              attribute.mustGetAttribute('type', forType).toTypeName(),
            ),
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
      final type = resolveType(
        element.mustGetAttribute('type', forType).toTypeName(),
      );
      return PropertyImplementation(
        docs: docs,
        name: Casing.camelCase(element.mustGetAttribute('name', forType)),
        type: maxOccurs > 1 ? ListType(itemType: type) : type,
        isNullable: minOccurs == 0 && maxOccurs == 1,
        isOverridden: false,
      );
    });
  }

  Iterable<Interface> interfaces(String forType) {
    return attributeGroupElements
        .map(
          (attributeGroup) =>
              attributeGroup.mustGetAttribute('ref', forType).toInterfaceName(),
        )
        .map(resolveInterface);
  }

  Interface toInterface() {
    final typeName = this.typeName;
    return Interface(
      name: typeName.toInterfaceName(),
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
      baseType: resolveType(
        extension.mustGetAttribute('base', typeName).toTypeName(),
      ),
    );
  }
}

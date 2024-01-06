import '../schema.dart';
import '../xml_extensions.dart';

mixin ReferenceMixin<T> implements XmlOwner {
  static const String xmlName = 'ref';
  String get reference => xml.mustGetAttribute(xmlName);
  T get refersTo;
}

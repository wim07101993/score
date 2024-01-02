part of 'code.dart';

class Interface extends ComplexType {
  Interface({
    required super.name,
    required super.docs,
    required super.properties,
    required super.interfaces,
  });

  @override
  void writeTo(IOSink sink) {
    // ignore: avoid_print
    print('writing interface $name');
    writeDocs(sink);

    sink.write('abstract class $name ');
    if (interfaces.isNotEmpty) {
      sink.write('implements ${interfaces.map((i) => i.name).join(', ')} ');
    }
    sink.writeln('{');

    for (final property in properties) {
      property.writeTo(sink);
    }
    sink.writeln('}');
  }
}

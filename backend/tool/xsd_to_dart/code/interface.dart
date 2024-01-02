part of 'code.dart';

class Interface extends ComplexType {
  Interface({
    required String name,
    required super.docs,
    required super.properties,
    required super.interfaces,
  }) : super(name: '${name}Group');

  @override
  void writeTo(IOSink sink) {
    // ignore: avoid_print
    print('writing interface $name');
    writeDocs(sink);

    sink.write('abstract class $name ');
    if (interfaces.isNotEmpty) {
      sink.write('implements ${interfaces.join(', ')} ');
    }
    sink.writeln('{');

    for (final property in properties) {
      property.writeTo(sink);
    }
    sink.writeln('}');
  }
}

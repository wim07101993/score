import 'dart:io';

class ConstructorParameter {
  const ConstructorParameter({
    required this.name,
    this.isRequired = false,
    this.comesFromSuper = false,
  });

  final String name;
  final bool isRequired;
  final bool comesFromSuper;

  void writeTo(IOSink sink) {
    sink.write('    ');
    if (isRequired) {
      sink.write('required ');
    }
    if (comesFromSuper) {
      sink.write('super');
    } else {
      sink.write('this');
    }

    sink.writeln('.$name,');
  }
}

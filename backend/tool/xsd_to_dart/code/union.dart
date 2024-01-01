import '../code_sink.dart';
import 'code.dart';

class Union extends Code {
  const Union({
    required super.docs,
    required this.name,
    required this.types,
  });

  final String name;
  final List<String> types;

  @override
  void writeTo(CodeSink sink) {
    // we write unions by hand since it are not as many
  }
}

import 'dart:io';

class CodeSink {
  const CodeSink({
    required this.enumSink,
    required this.aliasSink,
    required this.unionsSink,
    required this.interfacesSink,
  });

  final IOSink enumSink;
  final IOSink aliasSink;
  final IOSink unionsSink;
  final IOSink interfacesSink;

  Future<void> flush() {
    return Future.wait([
      enumSink.flush(),
      aliasSink.flush(),
      unionsSink.flush(),
      interfacesSink.flush(),
    ]);
  }
}

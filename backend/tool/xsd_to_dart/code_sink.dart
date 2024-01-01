import 'dart:io';

class CodeSink {
  const CodeSink({
    required this.enumSink,
    required this.aliasSink,
  });

  final IOSink enumSink;
  final IOSink aliasSink;

  Future<void> flush() {
    return Future.wait([
      enumSink.flush(),
      aliasSink.flush(),
    ]);
  }
}

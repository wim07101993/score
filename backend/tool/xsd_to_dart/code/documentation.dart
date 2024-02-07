import 'dart:io';

class Docs {
  const Docs({
    required this.lines,
    this.indent = 0,
  });

  final List<String> lines;
  final int indent;

  void writeTo(IOSink sink) {
    if (lines.isEmpty) {
      return;
    }
    for (final line in lines.expand((doc) => doc.split('\n'))) {
      sink.write(''.padLeft(indent * 2));
      sink.write('/// ');
      sink.writeln(line);
    }
  }
}

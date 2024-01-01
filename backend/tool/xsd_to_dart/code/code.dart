import 'dart:io';

import '../code_sink.dart';

abstract class Code {
  const Code({
    required this.docs,
  });

  final List<String> docs;

  void writeTo(CodeSink sink);

  void writeDocs(IOSink sink) {
    if (docs.isEmpty) {
      return;
    }
    for (final doc in docs.expand((doc) => doc.split('\n'))) {
      sink.write('/// ');
      sink.writeln(doc);
    }
  }
}

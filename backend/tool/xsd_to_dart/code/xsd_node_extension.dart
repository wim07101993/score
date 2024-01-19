import 'dart:io';

import '../xsd/annotation.dart';

extension XsdNodeExtension on Annotation {
  void writeDocs(IOSink sink, {int indent = 0}) {
    final docs = documentation;
    if (docs.isEmpty) {
      return;
    }
    for (final doc in docs.expand((doc) => doc.split('\n'))) {
      sink.write(''.padLeft(indent));
      sink.write('/// ');
      sink.writeln(doc);
    }
  }
}

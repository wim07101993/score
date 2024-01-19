import 'dart:io';

import '../xsd/schema.dart';

extension XsdNodeExtension on XsdNode {
  List<String> get docs {
    return annotation?.documentation ?? const [];
  }

  void writeDocs(IOSink sink, {int indent = 0}) {
    final docs = this.docs;
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

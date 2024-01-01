import 'dart:io';

import 'package:dart_casing/dart_casing.dart';

part 'alias.dart';
part 'enum.dart';
part 'interface.dart';
part 'union.dart';

abstract class Code {
  const Code({
    required this.docs,
  });

  final List<String> docs;

  void writeTo(IOSink sink);

  void writeDocs(IOSink sink, {int indent = 0}) {
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

sealed class Type extends Code {
  const Type({
    required super.docs,
  });
}

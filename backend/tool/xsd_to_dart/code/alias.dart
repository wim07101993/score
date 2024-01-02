part of 'code.dart';

class Alias extends Type {
  Alias({
    required super.name,
    required List<String> docs,
    required this.baseType,
    this.minInclusive,
    this.maxInclusive,
    this.pattern,
  }) : super(
          docs: [
            ...docs,
            if (minInclusive != null || maxInclusive != null || pattern != null)
              '',
            if (minInclusive != null) 'min inclusive: $minInclusive',
            if (maxInclusive != null) 'max inclusive: $maxInclusive',
            if (pattern != null) 'pattern: $pattern',
          ],
        );

  final String baseType;
  final String? minInclusive;
  final String? maxInclusive;
  final String? pattern;

  @override
  void writeTo(IOSink sink) {
    // ignore: avoid_print
    print('writing alias $name');
    writeDocs(sink);

    sink.writeln('typedef $name = $baseType;');
  }
}

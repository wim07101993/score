part of 'code.dart';

class Alias extends Type {
  Alias({
    required this.name,
    required this.baseType,
    required List<String> docs,
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

  final String name;
  final String baseType;
  final String? minInclusive;
  final String? maxInclusive;
  final String? pattern;

  @override
  void writeTo(IOSink sink) {
    print('writing alias $name');
    writeDocs(sink);

    sink
      ..writeln('typedef $name = $baseType;')
      ..writeln();
  }
}

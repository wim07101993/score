part of 'code.dart';

sealed class NativeType extends Type {
  const NativeType(String name) : super(docs: const [], name: name);

  @override
  void writeTo(IOSink sink) {
    throw Exception('native types should not be defined again');
  }
}

class Int extends NativeType {
  const Int() : super('int');
}

class Double extends NativeType {
  const Double() : super('double');
}

class StringType extends NativeType {
  const StringType() : super('String');
}

class ListType with Code implements NativeType {
  const ListType({
    this.docs = const [],
    required this.itemType,
  });

  @override
  final List<String> docs;
  @override
  String get name => 'List<${itemType.name}>';
  final Type itemType;

  @override
  void writeTo(IOSink sink) {
    throw Exception('native types should not be defined again');
  }
}

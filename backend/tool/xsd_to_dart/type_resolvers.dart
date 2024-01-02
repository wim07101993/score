import 'code/code.dart';
import 'globals.dart';

Interface resolveInterface(String name) {
  return allTypes.whereType<Interface>().firstWhere(
        (interface) => interface.name == name,
        orElse: () => throw Exception('no interface with name $name'),
      );
}

Type resolveType(String name) {
  return allTypes.whereType<Type>().firstWhere(
        (c) => c.name == name,
        orElse: () => throw Exception('no type with name $name'),
      );
}

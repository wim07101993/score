import 'dart:async';

import 'package:get_it/get_it.dart';

abstract class Feature {
  const Feature();

  List<Type> get dependencies => const [];

  void registerTypes(GetIt getIt) {}

  Future<void> install(GetIt getIt) => Future.value();

  FutureOr<dynamic> dispose() {}

  @override
  String toString() => runtimeType.toString();
}

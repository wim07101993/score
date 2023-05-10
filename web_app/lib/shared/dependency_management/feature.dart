import 'dart:async';

import 'package:get_it/get_it.dart';

abstract class Feature {
  const Feature();

  List<Type> get dependencies => const [];

  void registerTypes(GetIt getIt) {}

  Future<void> install(GetIt getIt) => Future.value();

  FutureOr<void> dispose() {}

  @override
  String toString() => runtimeType.toString();
}

abstract class FeatureBase extends Feature {
  FeatureBase();

  List<StreamSubscription> subscriptions = [];

  @override
  List<Type> get dependencies => const [];

  @override
  void registerTypes(GetIt getIt) {}

  @override
  Future<void> install(GetIt getIt) => Future.value();

  @override
  FutureOr<void> dispose() async {
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
  }
}

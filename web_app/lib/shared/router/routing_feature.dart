import 'package:get_it/get_it.dart';
import 'package:score/shared/dependency_management/feature.dart';
import 'package:score/shared/router/app_router.dart';

class RoutingFeature extends Feature {
  const RoutingFeature();

  @override
  void registerTypes(GetIt getIt) {
    getIt.registerLazySingleton(() => AppRouter());
  }
}

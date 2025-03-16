import 'package:get_it/get_it.dart';
import 'package:score/routing/app_router.dart';

void registerRouterDependencies() {
  GetIt.I.registerLazySingleton(() => AppRouter());
}

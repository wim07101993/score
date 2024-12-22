import 'package:get_it/get_it.dart';
import 'package:score/features/auth/google_user_manager.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/routing/app_router.dart';
import 'package:score/routing/logged_in_guard.dart';

void registerRouterDependencies() {
  GetIt.I.registerLazySingletonAsync(
    () async => AppRouter(
      loggedInGuard: await GetIt.I.getAsync(),
    ),
  );
  GetIt.I.registerLazySingletonAsync(
    () async {
      // We wanted user-listenable to be a synchronous dependency because it
      // is requested from the widget tree. But it has an async dependency. To
      // make sure the dependency is initialized, we query it here.
      await GetIt.I.getAsync<GoogleUserManager>();
      return LoggedInGuard(
        user: GetIt.I.get(),
        logger: GetIt.I.logger('router'),
      );
    },
  );
}

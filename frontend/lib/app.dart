import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/routing/app_router.dart';

void registerApp() {
  GetIt.I.registerLazySingletonAsync(
    () async => App(
      router: await GetIt.I.getAsync<AppRouter>(),
    ),
  );
}

class App extends StatelessWidget {
  const App({
    super.key,
    required this.router,
  });

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router.config(
        reevaluateListenable: GetIt.I<ValueListenable<OidcUser?>>(),
      ),
    );
  }
}

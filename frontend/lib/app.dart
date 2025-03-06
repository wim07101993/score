import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/l10n/arb/app_localizations.dart';
import 'package:score/routing/app_router.dart';

void registerApp() {
  GetIt.I.registerLazySingletonAsync(
    () async => App(
      router: await GetIt.I.getAsync<AppRouter>(),
    ),
  );
}

// ignore: avoid_implementing_value_types
abstract class App implements Widget {
  factory App({
    required AppRouter router,
  }) {
    return _App(
      router: router,
    );
  }

  factory App.error({
    required Object? error,
  }) {
    return _ErrorApp(error: error);
  }
}

class _App extends StatelessWidget implements App {
  const _App({
    required this.router,
  });

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    const String title = 'Score';
    return MaterialApp.router(
      title: title,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router.config(
        reevaluateListenable: GetIt.I<ValueListenable<OidcUser?>>(),
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget implements App {
  const _ErrorApp({
    required this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: buildError(AppLocalizations.of(context)!, error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildError(AppLocalizations s, Object? error) {
    if (error is OidcException &&
        error.message == "Couldn't fetch the discoveryDocument") {
      return Text(s.couldNotFetchDiscoveryDocumentErrorMessage);
    }
    return Text(s.unknownErrorDialogMessage);
  }
}

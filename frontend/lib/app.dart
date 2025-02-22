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

class App extends StatelessWidget {
  const App({
    super.key,
    required this.router,
  }) : error = null;

  const App.error({
    super.key,
    required this.error,
  }) : router = null;

  final AppRouter? router;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    const String title = 'Score';
    final router = this.router;
    if (router != null) {
      return MaterialApp.router(
        title: title,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router.config(
          reevaluateListenable: GetIt.I<ValueListenable<OidcUser?>>(),
        ),
      );
    }

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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/app_update/new_version_bar.dart';
import 'package:score/features/observability/errors.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';
import 'package:score/features/settings/storage/theme_hint.dart';
import 'package:score/get_it.dart';
import 'package:score/router.dart';
import 'package:score/theme.dart';
import 'package:score/widgets/starting.dart';

void run() {
  // The addresses are paths — `/scores/abc` — rather than the `/#/scores/abc`
  // a Flutter web app uses unless it is told otherwise. Everywhere but the web
  // it does nothing.
  usePathUrlStrategy();

  // Read before anything has a navigator. On the web the engine forgets the
  // address the page was opened at as soon as the first navigator reports a
  // route.
  final initialRoute = WidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .defaultRouteName;

  // Build LogsController before it is asked. Otherwise, it won't collect logs
  // until the logs-page is opened.
  final _ = GetIt.I.get<LogsController>();
  catchUncaughtErrors(
    flutterErrors: GetIt.I.logger('flutter-error'),
    platformErrors: GetIt.I.logger('platform-error'),
  );

  GetIt.I.logger('run').info('starting app');

  runApp(ScoreApp(initialRoute: initialRoute));
}

class const ScoreApp({
  super.key,
  final String? initialRoute,
}) extends StatefulWidget {
  @override
  State<ScoreApp> createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  late final Future<SettingsNotifier> _started = _start();

  /// Builds what the first page needs, and works out who it is for.
  ///
  /// What is on this device is read before anything is shown and the syncs
  /// are started after: what is here is on screen straight away, and whatever
  /// the server has to add arrives when it arrives.
  Future<SettingsNotifier> _start() async {
    final getIt = GetIt.I;
    await getIt.resolveDependencies();
    return getIt<SettingsNotifier>();
  }

  /// The screen shown until there is an app to show. It cannot ask what this
  /// device prefers — that is one of the things being loaded — so it follows
  /// the machine, as an app that has been told nothing does.
  Widget _starting({Object? failure}) => Starting(
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    themeMode: rememberedThemeMode(),
    failure: failure,
  );

  late final _router = GetIt.I<AppRouter>();

  late final _routerConfig = _router.config(
    deepLinkTransformer: (uri) => SynchronousFuture(AppRouter.readable(uri)),
    // The address the app was opened at is the one read before the starting
    // screen had a navigator; see [run].
    deepLinkBuilder: (link) => _router.deepLinkTo(
      link.initial ? widget.initialRoute ?? link.path : '${link.uri}',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SettingsNotifier>(
      future: _started,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _starting(failure: snapshot.error);
        }
        final settings = snapshot.data;
        if (settings == null) {
          return _starting();
        }

        return ListenableBuilder(
          listenable: settings,
          builder: (context, _) => MaterialApp.router(
            title: 'Score',
            debugShowCheckedModeBanner: false,
            theme: appTheme(Brightness.light),
            darkTheme: appTheme(Brightness.dark),
            themeMode: settings.themeMode,
            routerConfig: _routerConfig,
            builder: (context, child) => NewVersionBar(child: child!),
          ),
        );
      },
    );
  }
}

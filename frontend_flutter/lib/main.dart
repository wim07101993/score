import 'package:flutter/material.dart';

import 'app.dart';
import 'ui/routes.dart';
import 'ui/score_detail_page.dart';
import 'ui/scores_page.dart';
import 'ui/set_detail_page.dart';
import 'ui/sets_page.dart';
import 'ui/profile_page.dart';
import 'ui/settings_page.dart';
import 'ui/starting.dart';
import 'ui/theme.dart';

void main() {
  runApp(const ScoreApp());
}

class ScoreApp extends StatefulWidget {
  const ScoreApp({super.key});

  @override
  State<ScoreApp> createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  late final Future<App> _app = App.start();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<App>(
      future: _app,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _starting(failure: snapshot.error);
        }
        final app = snapshot.data;
        if (app == null) {
          return _starting();
        }

        return AppScope(
          app: app,
          child: ListenableBuilder(
            // The one thing above the app that a page can change. Everything
            // else here is settled by the time anything is drawn.
            listenable: app.settings,
            builder: (context, _) => MaterialApp(
              title: 'Score',
              debugShowCheckedModeBanner: false,
              theme: appTheme(Brightness.light),
              darkTheme: appTheme(Brightness.dark),
              themeMode: app.settings.themeMode,
              onGenerateRoute: _route,
              onGenerateInitialRoutes: _initialRoutes,
            ),
          ),
        );
      },
    );
  }

  /// Where a path leads.
  ///
  /// The addresses are the ones the app it replaces used, so a link a player has
  /// in their browser or written down still opens the score it always opened —
  /// including one into a set, which carries which set and which entry of it.
  /// The screen shown until there is an app to show. It cannot ask what this
  /// device prefers — that is one of the things being loaded — so it follows
  /// the machine, as an app that has been told nothing does.
  Widget _starting({Object? failure}) => Starting(
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        failure: failure,
      );

  Route<dynamic> _route(RouteSettings settings) =>
      _page(AppRoute.parse(settings.name), settings);

  MaterialPageRoute<void> _page(AppRoute target, RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => switch (target) {
        ScoresRoute() => const ScoresPage(),
        ScoreDetailRoute(:final scoreId, :final setId, :final entryId) =>
          ScoreDetailPage(scoreId: scoreId, setId: setId, entryId: entryId),
        SetsRoute() => const SetsPage(),
        SetDetailRoute(:final setId) => SetDetailPage(setId: setId),
        ProfileRoute() => const ProfilePage(),
        SettingsRoute() => const SettingsPage(),
      },
    );
  }

  /// The pages the app is opened onto, when it is opened at an address rather
  /// than walked to it. What that stack should be is
  /// [AppRoute.stackFor]'s business; this only turns each one into a page.
  List<Route<dynamic>> _initialRoutes(String initial) => [
        for (final route in AppRoute.stackFor(initial))
          _page(route, RouteSettings(name: route.path)),
      ];
}

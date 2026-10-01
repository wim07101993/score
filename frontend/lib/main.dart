import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:score/app.dart';
import 'package:score/features/app_update/new_version_bar.dart';
import 'package:score/features/auth/widgets/profile_page.dart';
import 'package:score/features/collections/widgets/collection_detail_page.dart';
import 'package:score/features/collections/widgets/collections_page.dart';
import 'package:score/features/scores/widgets/score_detail_page.dart';
import 'package:score/features/scores/widgets/scores_page.dart';
import 'package:score/features/sets/widgets/set_detail_page.dart';
import 'package:score/features/sets/widgets/sets_page.dart';
import 'package:score/features/settings/theme_hint.dart';
import 'package:score/features/settings/widgets/settings_page.dart';
import 'package:score/routes.dart';
import 'package:score/theme.dart';
import 'package:score/widgets/starting.dart';

void main() {
  // The addresses are paths — `/scores/abc` — as they were in the app this
  // replaces, rather than the `/#/scores/abc` a Flutter web app uses unless it
  // is told otherwise. Without this a link written down before would reach the
  // app as `/`. Everywhere but the web it does nothing.
  usePathUrlStrategy();
  // Read before anything has a navigator. On the web the engine forgets the
  // address the page was opened at as soon as the first navigator reports a
  // route — which the starting screen's does — so the app that replaces it
  // would otherwise always open on the list of scores, whatever link it was
  // opened from.
  final initialRoute = WidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .defaultRouteName;
  // The text font is shipped with the app (see pubspec.yaml), and its licence
  // goes with it.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Roboto'],
      await rootBundle.loadString('assets/fonts/roboto/LICENSE.txt'),
    );
  });
  runApp(ScoreApp(initialRoute: initialRoute));
}

class ScoreApp extends StatefulWidget {
  const ScoreApp({
    super.key,
    this.initialRoute,
  });

  /// The address the app was opened at. See [main] for why it is handed over
  /// rather than read when the app is built.
  final String? initialRoute;

  @override
  State<ScoreApp> createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  late final Future<App> _app = App.start();

  /// The screen shown until there is an app to show. It cannot ask what this
  /// device prefers — that is one of the things being loaded — so it follows
  /// the machine, as an app that has been told nothing does.
  Widget _starting({Object? failure}) => Starting(
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: rememberedThemeMode(),
        failure: failure,
      );

  /// Where a path leads.
  ///
  /// The addresses are the ones the app it replaces used, so a link a player has
  /// in their browser or written down still opens the score it always opened —
  /// including one into a set, which carries which set and which entry of it.
  Route<dynamic> _route(RouteSettings settings) =>
      _page(AppRoute.parse(settings.name), settings);

  MaterialPageRoute<void> _page(AppRoute target, RouteSettings settings) {
    Widget builder(BuildContext context) => switch (target) {
          ScoresRoute() => const ScoresPage(),
          ScoreDetailRoute(
            :final scoreId,
            :final setId,
            :final collectionId,
            :final entryId,
          ) =>
            ScoreDetailPage(
              scoreId: scoreId,
              setId: setId,
              collectionId: collectionId,
              entryId: entryId,
            ),
          SetsRoute() => const SetsPage(),
          SetDetailRoute(:final setId) => SetDetailPage(setId: setId),
          CollectionsRoute() => const CollectionsPage(),
          CollectionDetailRoute(:final collectionId) =>
            CollectionDetailPage(collectionId: collectionId),
          ProfileRoute() => const ProfilePage(),
          SettingsRoute() => const SettingsPage(),
        };

    return settings.arguments == AppRoute.renamed
        ? _RenamedPageRoute<void>(settings: settings, builder: builder)
        : MaterialPageRoute<void>(settings: settings, builder: builder);
  }

  /// The pages the app is opened onto, when it is opened at an address rather
  /// than walked to it. What that stack should be is
  /// [AppRoute.stackFor]'s business; this only turns each one into a page.
  List<Route<dynamic>> _initialRoutes(String initial) => [
        for (final route in AppRoute.stackFor(initial))
          _page(route, RouteSettings(name: route.path)),
      ];

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
              initialRoute: widget.initialRoute,
              onGenerateRoute: _route,
              onGenerateInitialRoutes: _initialRoutes,
              builder: (context, child) => NewVersionBar(child: child!),
            ),
          ),
        );
      },
    );
  }
}

/// A page swapped in for the one it already was, under the name it has just
/// been given. It is there at once rather than drawn arriving, and leaves the
/// way any other page does.
class _RenamedPageRoute<T> extends MaterialPageRoute<T> {
  _RenamedPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => super.transitionDuration;
}

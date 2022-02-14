import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/is_signed_in_notifier.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart';
import 'package:score/theme.dart';

class ScoreApp extends StatefulWidget {
  const ScoreApp({Key? key}) : super(key: key);

  @override
  State<ScoreApp> createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<IsSignedInNotifier>(
      builder: (context, isSignedIn, widget) => MaterialApp.router(
        title: 'Score',
        theme: lightTheme,
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterFireUILocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        routeInformationParser: _router.defaultRouteParser(
          includePrefixMatches: true,
        ),
        routerDelegate: AutoRouterDelegate.declarative(
          _router,
          routes: (context) => routes(isSignedIn: isSignedIn.value),
        ),
      ),
    );
  }

  List<PageRouteInfo> routes({
    required bool isSignedIn,
  }) {
    return [
      if (isSignedIn)
        const AuthorizedRouter(children: [ScoresListRoute()])
      else
        const SignInRoute(),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'package:score/app_router.dart';
import 'package:score/globals.dart';

class ScoreApp extends StatefulWidget {
  const ScoreApp({Key? key}) : super(key: key);

  @override
  State<ScoreApp> createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterFireUILocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      routerDelegate: _router.delegate(initialRoutes: [
        const LogRoute(),
      ]),
      routeInformationParser: _router.defaultRouteParser(),
    );
  }
}

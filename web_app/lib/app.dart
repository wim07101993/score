import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'package:provider/provider.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart';
import 'package:score/router/auth_guard.dart';
import 'package:score/theme.dart';

class ScoreApp extends StatefulWidget {
  const ScoreApp({super.key});

  @override
  State<ScoreApp> createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(
      authGuard: AuthGuard(auth: context.read<GetIt>()()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerDelegate: AutoRouterDelegate(_router),
      routeInformationParser: _router.defaultRouteParser(),
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/dc.dart';

import 'app_router.gr.dart';

class App extends StatelessWidget {
  App({
    required this.getIt,
    required this.isLoggedIn,
  }) : _appRouter = AppRouter();

  final AppRouter _appRouter;
  final GetIt getIt;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return ScoreAppProvider(
      getIt: getIt,
      child: MaterialApp.router(
        title: 'Score',
        theme: ThemeData(),
        routerDelegate: AutoRouterDelegate.declarative(
          _appRouter,
          routes: (_) => [
            const LogInRoute(),
          ],
        ),
        routeInformationParser: _appRouter.defaultRouteParser(
          includePrefixMatches: true,
        ),
      ),
    );
  }
}

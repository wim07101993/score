import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/dc.dart';

import 'app_router.dart';
import 'data/firebase/user/user.dart';

class App extends StatelessWidget {
  App({
    required this.getIt,
    required this.user,
  }) : _appRouter = AppRouter();

  final AppRouter _appRouter;
  final GetIt getIt;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final user = this.user;
    return ScoreAppProvider(
      getIt: getIt,
      child: MaterialApp.router(
        title: 'Score',
        theme: ThemeData(),
        routerDelegate: AutoRouterDelegate(
          _appRouter,
          initialRoutes: [
            if (user == null)
              const LogInRoute()
            else if (!user.accessLevels.application)
              const WaitingForAccessRoute()
            else
              const HomeRoute(),
          ],
        ),
        routeInformationParser: _appRouter.defaultRouteParser(
          includePrefixMatches: true,
        ),
      ),
    );
  }
}

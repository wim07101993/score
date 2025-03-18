import 'package:auto_route/auto_route.dart';
import 'package:score/routing/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(
        page: HomeRoute.page,
        initial: true,
        path: '/',
        children: [
          AutoRoute(page: LandingRoute.page, path: '', initial: true),
          AutoRoute(page: ScoreRoute.page, path: 'score/:id'),
        ],
      ),
      AutoRoute(page: UserInfoRoute.page, path: '/user-info'),
      AutoRoute(page: LogsRoute.page, path: '/developer/logs'),
    ];
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:score/routing/app_router.gr.dart';
import 'package:score/routing/logged_in_guard.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter({
    required this.loggedInGuard,
  });

  final LoggedInGuard loggedInGuard;

  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(
        page: HomeRoute.page,
        guards: [loggedInGuard],
        initial: true,
        path: '/',
      ),
      AutoRoute(page: LogInRoute.page, path: '/log-in'),
      AutoRoute(page: UserInfoRoute.page, path: '/user-info'),
      AutoRoute(page: LogsRoute.page, path: '/developer/logs'),
    ];
  }
}

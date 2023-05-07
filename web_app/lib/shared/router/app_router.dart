import 'package:auto_route/auto_route.dart';
import 'package:score/shared/router/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(path: '/', page: HomeRoute.page),
      AutoRoute(path: '/sign-in', page: SignInRoute.page)
    ];
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:core/core.dart';

import 'features/home/widget/home_screen.dart';
import 'features/user/widgets/log_in_screen.dart';
import 'features/user/widgets/waiting_for_access_screen.dart';

part 'app_router.gr.dart';

@MaterialAutoRouter(replaceInRouteName: 'Screen,Route', routes: [
  AutoRoute(page: LogInScreen),
  AutoRoute(page: HomeScreen),
  AutoRoute(page: WaitingForAccessScreen),
  // RedirectRoute(path: '*', redirectTo: HomeRoute.name),
])
class AppRouter extends _$AppRouter {
  AppRouter([GlobalKey<NavigatorState>? navigatorKey]) : super(navigatorKey);
}

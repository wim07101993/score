import 'package:auto_route/auto_route.dart';

import 'features/home/widget/home_screen.dart';
import 'features/user/widgets/log_in_screen.dart';
import 'features/user/widgets/waiting_for_access_screen.dart';

@MaterialAutoRouter(replaceInRouteName: 'Screen,Route', routes: [
  AutoRoute(page: LogInScreen),
  AutoRoute(page: HomeScreen),
  AutoRoute(page: WaitingForAccessScreen),
  // RedirectRoute(path: '*', redirectTo: HomeRoute.name),
])
class $AppRouter {}

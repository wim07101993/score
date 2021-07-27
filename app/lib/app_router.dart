import 'package:auto_route/auto_route.dart';
import 'package:score/app_router.gr.dart';

import 'features/home/widget/home_screen.dart';
import 'features/user/widgets/log_in_screen.dart';

@MaterialAutoRouter(replaceInRouteName: 'Screen,Route', routes: [
  AutoRoute(page: LogInScreen, initial: true),
  AutoRoute(page: HomeScreen, initial: true),
  RedirectRoute(path: '*', redirectTo: HomeRoute.name),
])
class $AppRouter {}

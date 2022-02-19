import 'package:auto_route/auto_route.dart';
import 'package:score/features/new_score/widgets/create_new_score_screen.dart';
import 'package:score/features/scores/widgets/scores_list_screen.dart';
import 'package:score/features/user/widgets/profile_screen.dart';
import 'package:score/features/user/widgets/sign_in_screen.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: [
    AutoRoute(page: SignInScreen),
    AutoRoute(
      path: 'authorized',
      name: 'authorizedRouter',
      page: EmptyRouterPage,
      children: [
        AutoRoute(page: ProfileScreen),
        AutoRoute(page: ScoresListScreen),
        AutoRoute(page: CreateNewScoreScreen),
      ],
    ),
  ],
)
class $AppRouter {}

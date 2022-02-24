import 'package:auto_route/auto_route.dart';
import 'package:score/features/new_score/widgets/create_new_score_page.dart';
import 'package:score/features/scores/widgets/scores_list_page.dart';
import 'package:score/features/user/widgets/profile_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: [
    AutoRoute(page: ProfilePage),
    AutoRoute(page: ScoresListPage),
    AutoRoute(page: CreateNewScorePage),
  ],
)
class $AppRouter {}

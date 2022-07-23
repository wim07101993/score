import 'package:auto_route/auto_route.dart';
import 'package:score/features/new_score/widgets/add_arrangement_form.dart';
import 'package:score/features/new_score/widgets/create_new_score_page.dart';
import 'package:score/features/new_score/widgets/new_score_form.dart';
import 'package:score/features/scores/widgets/scores_list_page.dart';
import 'package:score/features/user/widgets/profile_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: [
    AutoRoute(page: ScoresListPage, initial: true),
    AutoRoute(page: ProfilePage),
    AutoRoute(
      page: CreateNewScorePage,
      children: [
        AutoRoute(page: NewScoreForm, path: ''),
        AutoRoute(page: AddArrangementForm, path: ''),
      ],
    )
  ],
)
class $AppRouter {}

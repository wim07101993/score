import 'package:auto_route/auto_route.dart';
import 'package:score/features/new_score/widgets/add_arrangement_form.dart';
import 'package:score/features/new_score/widgets/create_new_score_page.dart';
import 'package:score/features/new_score/widgets/new_score_form.dart';
import 'package:score/features/scores/widgets/scores_list_page.dart';
import 'package:score/features/user/widgets/profile_page.dart';
import 'package:score/features/user/widgets/sign_in_screen.dart';
import 'package:score/home/widgets/home.dart';
import 'package:score/router/auth_guard.dart';

class Paths {
  static const home = '';
  static const scoresList = 'scores-list';
  static const siging = 'signin';
  static const profile = 'user/profile';
  static const newScore = 'new-score';
  static const newScoreForm = '$newScore/score-details';
  static const addArrangementForm = '$newScore/arrangement/:arrangementIndex';
}

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: [
    AutoRoute(
      path: Paths.home,
      page: Home,
      initial: true,
      guards: [AuthGuard],
      children: [
        RedirectRoute(path: Paths.home, redirectTo: Paths.scoresList),
        AutoRoute(path: Paths.scoresList, page: ScoresListPage),
        AutoRoute(path: Paths.profile, page: ProfilePage),
        AutoRoute(
          path: Paths.newScoreForm,
          page: CreateNewScorePage,
          children: [
            RedirectRoute(path: Paths.home, redirectTo: Paths.newScoreForm),
            AutoRoute(path: Paths.newScoreForm, page: NewScoreForm),
            AutoRoute(path: Paths.addArrangementForm, page: AddArrangementForm),
          ],
        ),
      ],
    ),
    AutoRoute(path: Paths.siging, page: SignInScreen),
  ],
)
class $AppRouter {}

import 'package:auto_route/auto_route.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:score/features/auth/user.dart';
import 'package:score/routing/app_router.gr.dart';

class LoggedInGuard extends AutoRouteGuard {
  const LoggedInGuard({
    required this.user,
    required this.logger,
  });

  final UserListenable user;
  final Logger logger;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (user.value != null) {
      resolver.next();
    } else {
      logger.info('user not logged in, redirecting to log-in screen');
      resolver.redirectUntil(const LogInRoute());
    }
  }
}

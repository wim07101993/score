import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:score/router/app_router.gr.dart';

class AuthGuard extends AutoRouteGuard {
  AuthGuard({
    required this.auth,
  });

  final FirebaseAuth auth;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (auth.currentUser != null) {
      resolver.next();
    } else {
      router.push(SignInScreen(onSignedIn: () {
        // if success == true the navigation will be resumed
        // else it will be aborted
        router.replace(resolver.route.toPageRouteInfo());
      }));
    }
  }
}

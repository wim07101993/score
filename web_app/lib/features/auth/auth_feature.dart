import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, User;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/models/user_value.dart';
import 'package:score/shared/dependency_management/feature.dart';
import 'package:score/shared/firebase/firebase_feature.dart';
import 'package:score/shared/router/app_router.dart';
import 'package:score/shared/router/app_router.gr.dart';
import 'package:score/shared/router/routing_feature.dart';

class AuthFeature extends FeatureBase {
  AuthFeature();

  @override
  List<Type> get dependencies => const [FirebaseFeature, RoutingFeature];

  @override
  void registerTypes(GetIt getIt) {
    getIt.registerLazySingleton(() => FirebaseAuth.instance);
    getIt.registerLazySingleton(() => const FirebaseUserConverter());
    getIt.registerLazySingleton<List<AuthProvider>>(
      () => [EmailAuthProvider()],
    );

    getIt.registerLazySingletonAsync(
      () => UserValue(
        firebaseAuth: getIt(),
        firebaseUserConverter: getIt(),
      ).initialize(),
    );
  }

  @override
  Future<void> install(GetIt getIt) async {
    final userValue = await getIt.getAsync<UserValue>();
    subscriptions.add(
      userValue.changes.listen((user) => onUserChanged(getIt, user)),
    );
    onUserChanged(getIt, userValue.value);
  }

  void onUserChanged(GetIt getIt, User? user) {
    final router = getIt<AppRouter>();
    if (user == null) {
      router.push(const SignInRoute());
    } else if (router.stack.length == 1) {
      router.replace(const HomeRoute());
    } else {
      router.popUntilRouteWithName(const SignInRoute().routeName);
      router.pop();
    }
  }
}

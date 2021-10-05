import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthChanges extends ValueNotifier<User?> {
  AuthChanges({
    required Logger logger,
    required FirebaseAuth firebaseAuth,
  }) : super(firebaseAuth.currentUser) {
    _authChangeSubscription = firebaseAuth.authStateChanges().listen((user) {
      if (user == null) {
        logger.i('user logged out');
      } else {
        logger.i('welcome back ${user.displayName}');
      }
      value = user;
    });
  }

  StreamSubscription? _authChangeSubscription;

  @override
  void dispose() {
    _authChangeSubscription?.cancel();
    super.dispose();
  }
}

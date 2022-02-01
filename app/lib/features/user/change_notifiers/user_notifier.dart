import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

class UserNotifier extends ValueNotifier<User?> {
  UserNotifier({
    required FirebaseAuth firebaseAuth,
  }) : super(
    firebaseAuth.currentUser == null
        ? null
        : User.fromFirebase(firebaseAuth.currentUser!),
  ) {
    _firebaseUserSubscription = firebaseAuth.userChanges().listen((newUser) {
      user = newUser == null ? null : User.fromFirebase(newUser);
    });
  }

  late final StreamSubscription _firebaseUserSubscription;

  User? get user => value;

  set user(User? user) => value = user;

  bool get isLoggedIn => value != null;

  @override
  void dispose() {
    super.dispose();
    _firebaseUserSubscription.cancel();
  }
}

abstract class User {
  const factory User.fromFirebase(fb.User firebaseUser) = _FirebaseUser;

  String get id;

  String? get displayName;
}

class _FirebaseUser implements User {
  const _FirebaseUser(this.firebaseUser);

  final fb.User firebaseUser;

  @override
  String get id => firebaseUser.uid;

  @override
  String? get displayName => firebaseUser.displayName;
}

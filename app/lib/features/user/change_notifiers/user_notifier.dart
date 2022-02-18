import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/features/user/data/firestore_extensions.dart';
import 'package:score/features/user/models/roles.dart';
import 'package:score/features/user/models/user.dart';

class UserNotifier extends ValueNotifier<User?> {
  UserNotifier({
    required this.auth,
    required this.firestore,
    required this.logger,
  }) : super(null) {
    _userChangesSubscription = auth.userChanges().listen((_) => refreshUser());
    refreshUser().then((_) => _initialized.complete(true));
  }

  final Completer<bool> _initialized = Completer();
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final Logger logger;

  late final StreamSubscription _userChangesSubscription;
  StreamSubscription? _userPropertiesChangesSubscription;

  Future<bool> get initialized => _initialized.future;

  User? get user => value;

  Future<void> _setUser(User? user) async {
    final userIdChanged = user?.id != this.user?.id;
    if (userIdChanged) {
      await _userPropertiesChangesSubscription?.cancel();
      _userPropertiesChangesSubscription = null;
    }
    value = user;
    if (userIdChanged && user != null) {
      _userPropertiesChangesSubscription =
          firestore.userPropertyChanges(user.id).listen(_userPropertiesChanged);
    }
  }

  bool get isSignedIn => value != null;

  @override
  void dispose() {
    super.dispose();
    _userChangesSubscription.cancel();
  }

  Future<void> refreshUser() async {
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) {
      return _setUser(null);
    }
    final email = firebaseUser.email;
    if (email == null) {
      logger.w('Firebase user without email: ${firebaseUser.uid}');
      return _setUser(null);
    }
    final userProperties = await firestore.securityProperties(firebaseUser.uid);
    return _setUser(User(
      id: firebaseUser.uid,
      email: email,
      displayName: firebaseUser.displayName,
      roles: userProperties,
    ));
  }

  Future<void> _userPropertiesChanged(Roles userProperties) async {
    final user = this.user;
    if (user == null) {
      logger.w('UserProperties changed while user is null. The subscription '
          'should have been canceled when the user changed!');
      return;
    }

    return _setUser(User(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      roles: userProperties,
    ));
  }
}

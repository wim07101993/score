import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/auth/google_user_manager.dart';

class UserListenable extends ChangeNotifier
    implements ValueListenable<OidcUser?> {
  UserListenable({
    required GoogleUserManager googleUserManager,
  }) {
    googleUserChangesSubscription =
        googleUserManager.userChanges().listen((user) {
      if (user == null) {
        _updateUser(null);
        return;
      }
    });
  }

  late final StreamSubscription googleUserChangesSubscription;

  OidcUser? _user;

  @override
  OidcUser? get value => _user;

  void _updateUser(OidcUser? newUser) {
    if (newUser == _user) {
      return;
    }
    _user = newUser;
    notifyListeners();
  }

  @override
  void dispose() {
    googleUserChangesSubscription.cancel();
    super.dispose();
  }
}

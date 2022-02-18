import 'package:flutter/material.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/features/user/models/roles.dart';

class RolesNotifier extends ValueNotifier<Roles?> {
  RolesNotifier({required this.userNotifier})
      : super(userNotifier.user?.roles) {
    userNotifier.addListener(onUserChanged);
  }

  final UserNotifier userNotifier;

  bool get hasReadAccess => value?.hasReadAccess ?? false;

  bool get hasContributorAccess => value?.hasContributionAccess ?? false;

  void onUserChanged() => value = userNotifier.user?.roles;
}

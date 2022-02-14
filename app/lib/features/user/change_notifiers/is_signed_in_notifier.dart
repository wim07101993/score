import 'package:flutter/cupertino.dart';
import 'package:score/features/user/change_notifiers/user/user_notifier.dart';

class IsSignedInNotifier extends ValueNotifier<bool> {
  IsSignedInNotifier({
    required this.userNotifier,
  }) : super(userNotifier.isSignedIn) {
    userNotifier.addListener(onUserChanged);
  }

  final UserNotifier userNotifier;

  void onUserChanged() => value = userNotifier.isSignedIn;

  @override
  void dispose() {
    super.dispose();
    userNotifier.removeListener(onUserChanged);
  }
}

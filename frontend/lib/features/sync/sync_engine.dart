import 'package:flutter/foundation.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/sync/behaviours/syncer.dart';

class SyncEngine({
  required final List<Syncer> Function() syncers,
  required final AuthNotifier userInfo,
  required final ValueNotifier<bool> isSyncing,
}) {
  this {
    userInfo.addListener(_onAuthChanged);
  }

  Future<void> sync() async {
    if (isSyncing.value) {
      return;
    }
    isSyncing.value = true;
    try {
      await Future.wait(syncers().map((syncer) async => syncer()));
    } finally {
      isSyncing.value = false;
    }
  }

  void _onAuthChanged() => sync();

  void dispose() {
    userInfo.removeListener(_onAuthChanged);
  }
}

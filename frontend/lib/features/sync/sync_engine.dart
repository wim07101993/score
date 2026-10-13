import 'package:behaviour/behaviour.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/sync/behaviours/syncer.dart';

class SyncEngine({
  required final List<Syncer> Function() syncers,
  required final AuthNotifier userInfo,
}) {
  this {
    userInfo.addListener(_onAuthChanged);
  }

  Future<List<ExceptionOr<void>>> sync() {
    return Future.wait(syncers().map((syncer) async => syncer()));
  }

  void _onAuthChanged() => sync();

  void dispose() {
    userInfo.removeListener(_onAuthChanged);
  }
}

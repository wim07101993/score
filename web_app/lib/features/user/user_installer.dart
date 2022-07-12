import 'package:hawk/hawk.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/features/user/behaviours/logout.dart';
import 'package:score/features/user/change_notifiers/is_signed_in_notifier.dart';
import 'package:score/features/user/change_notifiers/roles_notifier.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

class UserInstaller implements Installer {
  const UserInstaller();

  @override
  Future<void> initialize(GetIt getIt) async {
    getIt<EventHub>()
        .handlers
        .addFactory<LogoutEvent>(() => getIt<Logout>().onLogoutEvent);

    await getIt<UserNotifier>().initialized;
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton(
        () => UserNotifier(auth: getIt(), firestore: getIt(), logger: getIt()));
    getIt.registerFactory(() => IsSignedInNotifier(userNotifier: getIt()));
    getIt.registerFactory(() => RolesNotifier(userNotifier: getIt()));
  }
}

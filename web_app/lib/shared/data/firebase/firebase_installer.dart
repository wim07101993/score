import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/shared/data/firebase/firebase_options.dart';
import 'package:score/shared/data/firebase/provider_configurations.dart';
import 'package:score/shared/data/firebase/remote_config/remote_config_extensions.dart';

class FirebaseInstaller implements Installer {
  const FirebaseInstaller();

  @override
  Future<void> initialize(GetIt getIt) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final remoteConfig = getIt<FirebaseRemoteConfig>();
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.fetchAndActivate();
    getIt.logger<GetIt>().i('initialized firebase');
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton(() => const ProviderConfigurations());
    getIt.registerLazySingleton(() => FirebaseAuth.instance);
    getIt.registerLazySingleton(() => FirebaseFirestore.instance);
    getIt.registerLazySingleton(() => FirebaseRemoteConfig.instance);
    getIt.registerFactory(() => getIt<FirebaseRemoteConfig>().appConfig);
  }
}

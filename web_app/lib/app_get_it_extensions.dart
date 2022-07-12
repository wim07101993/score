import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:score/features/new_score/behaviours/save_new_score.dart';
import 'package:score/features/new_score/bloc/create_score_bloc.dart';
import 'package:score/features/user/user_installer.dart';
import 'package:score/shared/data/event_hub/event_hub_installer.dart';
import 'package:score/shared/data/firebase/firebase_installer.dart';
import 'package:score/shared/data/guid_generator.dart';
import 'package:score/shared/data/hive/hive_installer.dart';
import 'package:score/shared/data/logging/logging_installer.dart';

export 'package:get_it/get_it.dart';

Logger? _logger;

abstract class Installer {
  void registerDependencies(GetIt getIt);
  Future<void> initialize(GetIt getIt);
}

final _installers = [
  const HiveInstaller(),
  const LoggingInstaller(),
  const EventHubInstaller(),
  const FirebaseInstaller(),
  const UserInstaller(),
];

extension AppGetItExtensions on GetIt {
  void registerScore() {
    registerLazySingletonAsync(() => PackageInfo.fromPlatform());
    registerLazySingleton(() => const GuidGenerator());
    registerNewScore();
    for (final installer in _installers) {
      installer.registerDependencies(this);
    }
  }

  void registerNewScore() {
    registerFactory(() => CreateScoreBloc(saveNewScore: call()));
    registerFactory(() => SaveNewScore(
          monitor: call(),
          firestore: call(),
        ));
  }

  Future<void> initializeScore() {
    return Future.wait(_installers.map((installer) {
      return installer.initialize(this);
    }));
  }

  Logger logger(String loggerName) {
    return call<Logger>(param1: loggerName);
  }
}

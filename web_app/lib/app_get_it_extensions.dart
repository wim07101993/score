import 'package:behaviour/behaviour.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:score/features/new_score/new_score_installer.dart';
import 'package:score/features/scores/scores_installer.dart';
import 'package:score/features/user/user_installer.dart';
import 'package:score/shared/behaviours/standard_behaviour_monitor.dart';
import 'package:score/shared/data/algolia/algolia_installer.dart';
import 'package:score/shared/data/event_hub/event_hub_installer.dart';
import 'package:score/shared/data/firebase/firebase_installer.dart';
import 'package:score/shared/data/guid_generator.dart';
import 'package:score/shared/data/hive/hive_installer.dart';
import 'package:score/shared/data/logging/logging_installer.dart';

export 'package:get_it/get_it.dart';

abstract class Installer {
  void registerDependencies(GetIt getIt);
  Future<void> initialize(GetIt getIt);
}

final _installers = [
  const HiveInstaller(),
  const LoggingInstaller(),
  const EventHubInstaller(),
  const FirebaseInstaller(),
  const AlgoliaInstaller(),
  const UserInstaller(),
  const ScoresInstaller(),
  const NewScoreInstaller(),
];

extension AppGetItExtensions on GetIt {
  void registerScore() {
    registerLazySingletonAsync(() => PackageInfo.fromPlatform());
    registerLazySingleton(() => const GuidGenerator());
    for (final installer in _installers) {
      installer.registerDependencies(this);
    }
  }

  Future<void> initializeScore() async {
    for (final installer in _installers) {
      await installer.initialize(this);
    }
  }

  Logger logger<T>([String? loggerName]) {
    return call<Logger>(param1: loggerName ?? T.runtimeType.toString());
  }

  GetItBehaviourMonitor<T> monitor<T extends BehaviourTrack>() {
    return GetItBehaviourMonitor(getIt: this);
  }
}

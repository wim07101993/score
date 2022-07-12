import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/shared/data/logging/log_record_adapter.dart';

class HiveInstaller implements Installer {
  const HiveInstaller();

  @override
  Future<void> initialize(GetIt getIt) async {
    final hive = getIt<HiveInterface>();
    final packageInfo = await getIt.getAsync<PackageInfo>();
    await hive.initFlutter(packageInfo.appName);
    // use log here because logger needs hive...
    log('getIt: initialized hive');
  }

  @override
  void registerDependencies(GetIt getIt) {
    Hive
      ..registerAdapter(LogRecordAdapter())
      ..registerAdapter(LevelAdapter());
    getIt.registerSingleton(Hive);
  }
}

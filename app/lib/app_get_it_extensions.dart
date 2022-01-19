import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:score/data/firebase/provider_configurations.dart';
import 'package:score/data/guid_generator.dart';
import 'package:score/data/logging/hive_log_sink.dart';
import 'package:score/data/logging/log_record_adapter.dart';

export 'package:get_it/get_it.dart';

extension AppGetItExtensions on GetIt {
  Future<void> initializeScore() async {
    registerSingleton(await PackageInfo.fromPlatform());
    registerSingleton(const GuidGenerator());
    await _initializeHive();
    await _initializeLogging();
    await _initializeFirebase();
  }

  Future<void> _initializeHive() async {
    Hive
      ..registerAdapter(LogRecordAdapter())
      ..registerAdapter(LevelAdapter());
    Hive.initFlutter(call<PackageInfo>().appName);
    await getApplicationDocumentsDirectory().then((value) => print(value));
    registerSingleton(Hive);
  }

  Future<void> _initializeLogging() async {
    Logger.root.level = Level.ALL;
    hierarchicalLoggingEnabled = true;
    final simpleFormatter = SimpleFormatter();
    final prettyFormatter = PrettyFormatter();
    registerLazySingleton(
      () => HiveLogSink(guidGenerator: call(), hive: call()),
    );
    registerLazySingleton<LogSink>(
      () => MultiLogSink([
        PrintSink(LevelDependentFormatter(
          defaultFormatter: simpleFormatter,
          severe: prettyFormatter,
          shout: prettyFormatter,
        )),
        // DevLogSink(),
        call<HiveLogSink>(),
      ]),
    );
    registerFactoryParam((String loggerName, p2) {
      final logger = Logger(loggerName);
      call<LogSink>().listenTo(logger.onRecord);
      return logger;
    });
  }

  Future<void> _initializeFirebase() async {
    registerLazySingleton(() => const ProviderConfigurations());
  }

  Logger logger(String loggerName) {
    return call<Logger>(param1: loggerName);
  }
}

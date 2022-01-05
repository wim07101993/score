import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:score/data/firebase/provider_configurations.dart';
import 'package:score/data/guid_generator.dart';
import 'package:score/data/logging/hive_log_sink.dart';
import 'package:score/data/logging/log_record_adapter.dart';

export 'package:get_it/get_it.dart';

extension AppGetItExtensions on GetIt {
  Future<void> initializeScore() async {
    registerSingleton(const GuidGenerator());
    await _initializeHive();
    await _initializeLogging();
    await _initializeFirebase();
  }

  Future<void> _initializeHive() async {
    Hive
      ..registerAdapter(LogRecordAdapter())
      ..registerAdapter(LevelAdapter());
    Hive.initFlutter();
    registerSingleton(Hive);
  }

  Future<void> _initializeLogging() async {
    Logger.root.level = Level.ALL;
    hierarchicalLoggingEnabled = true;
    final simpleFormatter = SimpleFormatter();
    final prettyFormatter = PrettyFormatter();
    registerLazySingleton<LogSink>(
      () => MultiLogSink([
        MemoryLogSink.fixedBuffer(),
        PrintSink(LevelDependentFormatter(
          defaultFormatter: simpleFormatter,
          severe: prettyFormatter,
          shout: prettyFormatter,
        )),
        DevLogSink(),
        HiveLogSink(hive: call(), guidGenerator: call()),
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

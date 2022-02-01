import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:score/data/firebase/firebase_options.dart';
import 'package:score/data/firebase/provider_configurations.dart';
import 'package:score/data/guid_generator.dart';
import 'package:score/data/logging/hive_log_sink.dart';
import 'package:score/data/logging/log_record_adapter.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

export 'package:get_it/get_it.dart';

Logger? _logger;

extension AppGetItExtensions on GetIt {
  Future<void> initializeScore() async {
    registerSingleton(await PackageInfo.fromPlatform());
    registerSingleton(const GuidGenerator());

    await _initializeHive();
    _initializeLogging();
    await _initializeFirebase();

    _initializeUser();
  }

  Future<void> _initializeHive() async {
    Hive
      ..registerAdapter(LogRecordAdapter())
      ..registerAdapter(LevelAdapter());
    await Hive.initFlutter(call<PackageInfo>().appName);
    registerSingleton(Hive);
    // use log here because logger needs hive...
    log('getIt: initialized hive');
  }

  void _initializeLogging() {
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
    _logger = logger('getIt')..i('initialized logging');
  }

  Future<void> _initializeFirebase() async {
    registerLazySingleton(() => const ProviderConfigurations());
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    registerLazySingleton(() => FirebaseAuth.instance);
    _logger?.i('initialized firebase');
  }

  void _initializeUser() {
    registerSingleton(UserNotifier(firebaseAuth: call()));
  }

  Logger logger(String loggerName) {
    return call<Logger>(param1: loggerName);
  }
}

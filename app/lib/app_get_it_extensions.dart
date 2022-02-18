import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:score/features/user/change_notifiers/is_signed_in_notifier.dart';
import 'package:score/features/user/change_notifiers/roles_notifier.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

export 'package:get_it/get_it.dart';

Logger? _logger;

extension AppGetItExtensions on GetIt {
  void registerScore() {
    registerLazySingletonAsync(() => PackageInfo.fromPlatform());
    registerLazySingleton(() => const GuidGenerator());
    registerHive();
    registerLogging();
    registerFirebase();
    registerUser();
  }

  void registerHive() {
    Hive
      ..registerAdapter(LogRecordAdapter())
      ..registerAdapter(LevelAdapter());
    registerSingleton(Hive);
  }

  void registerLogging() {
    registerLazySingleton(
        () => HiveLogSink(guidGenerator: call(), hive: call()));
    registerLazySingleton<LogSink>(() {
      final simpleFormatter = SimpleFormatter();
      final prettyFormatter = PrettyFormatter();
      return MultiLogSink([
        PrintSink(LevelDependentFormatter(
          defaultFormatter: simpleFormatter,
          severe: prettyFormatter,
          shout: prettyFormatter,
        )),
        // DevLogSink(),
        call<HiveLogSink>(),
      ]);
    });
    registerFactoryParam((String loggerName, p2) {
      final logger = Logger(loggerName);
      call<LogSink>().listenTo(logger.onRecord);
      return logger;
    });
  }

  void registerFirebase() {
    registerLazySingleton(() => const ProviderConfigurations());
    registerLazySingleton(() => FirebaseAuth.instance);
    registerLazySingleton(() => FirebaseFirestore.instance);
  }

  void registerUser() {
    registerLazySingleton(() =>
        UserNotifier(auth: call(), firestore: call(), logger: logger('user')));
    registerFactory(() => IsSignedInNotifier(userNotifier: call()));
    registerFactory(() => RolesNotifier(userNotifier: call()));
  }

  Future<void> initializeScore() async {
    await _initializeHive();
    _initializeLogging();
    await _initializeFirebase();
    await _initializeUser();
  }

  Future<void> _initializeHive() async {
    final hive = call<HiveInterface>();
    final packageInfo = await getAsync<PackageInfo>();
    await hive.initFlutter(packageInfo.appName);
    // use log here because logger needs hive...
    log('getIt: initialized hive');
  }

  void _initializeLogging() {
    Logger.root.level = Level.ALL;
    hierarchicalLoggingEnabled = true;
    _logger = logger('getIt')..i('initialized logging');
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger?.i('initialized firebase');
  }

  Future<void> _initializeUser() async {
    await call<UserNotifier>().initialized;
  }

  Logger logger(String loggerName) {
    return call<Logger>(param1: loggerName);
  }
}

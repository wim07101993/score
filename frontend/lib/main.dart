import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/app.dart';
import 'package:score/features/auth/get_it.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/features/scores/get_it.dart';
import 'package:score/routing/get_it.dart';
import 'package:score/shared/api/get_it.dart';
import 'package:score/shared/libsql/get_it.dart';

void main() {
  runZonedGuarded(run, onError);
}

Future<void> run() async {
  registerLogging();
  registerLibsqlDependencies();

  final logger = GetIt.I.logger('main');
  final sink = GetIt.I<LogSink>();
  sink.listenTo(logger.onRecord);

  logger.info('registering dependencies');

  registerAuthDependencies();
  registerRouterDependencies();
  registerScoreDependencies();
  registerApi();
  registerApp();

  logger.info('initializing app');
  final App app;
  try {
    GetIt.I<ScoreSyncer>().start();
    app = await GetIt.I.getAsync<App>();
  } on OidcException catch (error, stacktrace) {
    logger.wtf('error while creating app', error, stacktrace);
    runApp(App.error(error: error));
    return;
  }
  logger.info('run app');
  runApp(app);
}

void onError(Object error, StackTrace stackTrace) {
  if (!GetIt.I.isRegistered<Logger>()) {
    log(
      'error in main',
      error: error,
      stackTrace: stackTrace,
      level: Level.SHOUT.value,
    );
    return;
  }

  try {
    final logger = GetIt.I.logger('main');
    logger.wtf('error in main', error, stackTrace);
  } catch (internalError, internalStacktrace) {
    log(
      'error while trying to log error',
      level: Level.SHOUT.value,
      error: internalError,
      stackTrace: internalStacktrace,
    );
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:score/app.dart';
import 'package:score/features/auth/get_it.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/routing/get_it.dart';

void main() {
  runZonedGuarded(run, onError);
}

Future<void> run() async {
  registerLogging();

  final logger = GetIt.I.logger('main');
  final sink = GetIt.I.get<LogSink>();
  sink.listenTo(logger.onRecord);

  logger.info('registering dependencies');

  registerAuthDependencies();
  registerRouterDependencies();
  registerApp();

  logger.info('initializing app');
  final app = await GetIt.I.getAsync<App>();
  logger.info('run app');
  runApp(app);
}

FutureOr<void> onError(Object error, StackTrace stackTrace) {
  if (!GetIt.I.isRegistered<Logger>()) {
    log(
      'error in main',
      error: error,
      stackTrace: stackTrace,
      level: Level.SHOUT.value,
    );
    return null;
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

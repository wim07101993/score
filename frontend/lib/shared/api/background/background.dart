import 'dart:async';
import 'dart:developer';

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:isolated/isolated.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/features/scores/get_it.dart';
import 'package:score/shared/api/generated/searcher.pb.dart';

const String isolateName = 'apiIsolate';

Future<IsolateBundle<IsolateBundleConfiguration, Object, Object>>
    startApiBackgroundIsolate() async {
  return const IsolateBundleFactory().startNew(
    _backgroundMain,
    (toBackgroundPort) => IsolateBundleConfiguration(toBackgroundPort),
    name: isolateName,
  );
}

Future<void> _backgroundMain(IsolateBundleConfiguration config) async {
  registerLogging();

  final logger = GetIt.I.logger('api isolate');
  final sink = GetIt.I<LogSink>();
  sink.listenTo(logger.onRecord);

  logger.info('registering dependencies');

  registerScoreDependencies();

  logger.info('initializing background isolate loop');
  config.activateOnCurrentIsolate<Object>(
    (message) => runZonedGuarded(() => handleMessage(message), onError),
    (cancel) => GetIt.instance.resetScope(),
  );
}

Future<void> handleMessage(Object message) async {
  switch (message) {
    case final GetScoresRequest getScoresRequest:
  }
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
    final logger = GetIt.I.logger(isolateName);
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

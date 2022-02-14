import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/app.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/app_provider.dart';

late Logger rootLogger;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.asNewInstance()..registerScore();
  await getIt.initializeScore();
  rootLogger = getIt<Logger>(param1: 'root');
  rootLogger.i('initialized dependency injection');
  runZonedGuarded(
    () => run(getIt),
    onError,
  );
}

void run(GetIt getIt) {
  runApp(AppProvider(
    getIt: getIt,
    child: const ScoreApp(),
  ));
}

void onError(Object error, StackTrace stackTrace) {
  try {
    rootLogger.shout('Error on main', error, stackTrace);
  } catch (nestedError, nestedStackTrace) {
    log(
      'Error on main',
      time: DateTime.now(),
      level: Level.SHOUT.value,
      error: error,
      stackTrace: stackTrace,
      zone: Zone.current,
      name: 'main',
    );
    log(
      'Error while trying to log exception',
      time: DateTime.now(),
      level: Level.SHOUT.value,
      error: nestedError,
      stackTrace: nestedStackTrace,
      zone: Zone.current,
      name: 'main',
    );
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'app.dart';
import 'dc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance..init();
  runZonedGuarded(() async {
    final userBox = getIt.userBox;
    runApp(App(
      getIt: getIt,
      isLoggedIn: await userBox.isLoggedIn(),
    ));
  }, (error, stackTrace) {
    try {
      getIt.prettyLogger.e('App crash', error, stackTrace);
    } catch (e, stackTrace) {
      log('App crash: $e at \r\n$stackTrace');
    }
  });
}

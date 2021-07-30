import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'app.dart';
import 'dc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final getIt = GetIt.instance..init();
  runZonedGuarded(() async {
    await initAuth();
    final userBox = getIt.userBox;
    runApp(App(
      getIt: getIt,
      isLoggedIn: await userBox.isLoggedIn(),
    ));
  }, (error, stackTrace) {
    try {
      getIt.prettyLogger.e('App crash', error, stackTrace);
    } catch (e) {
      log('App crash + log crash: $error at \r\n$stackTrace');
    }
  });
}

Future<void> initAuth() async {
  if (kIsWeb) {
    FacebookAuth.i.webInitialize(
      appId: '189190539900591',
      cookie: true,
      xfbml: true,
      version: 'v9.0',
    );
  }

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) {
      print('Not logged in');
    } else {
      print('Logged in');
    }
  });
}

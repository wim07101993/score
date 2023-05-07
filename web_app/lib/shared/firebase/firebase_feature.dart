import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/shared/dependency_management/feature.dart';
import 'package:score/shared/firebase/firebase_options.dart';

class FirebaseFeature extends Feature {
  const FirebaseFeature();

  @override
  void registerTypes(GetIt getIt) {
    getIt.registerSingleton(DefaultFirebaseOptions.currentPlatform);
  }

  @override
  Future<void> install(GetIt getIt) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

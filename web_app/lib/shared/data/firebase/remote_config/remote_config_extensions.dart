import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:score/shared/data/firebase/remote_config/app_config.dart';

extension RemoteConfigExtensions on FirebaseRemoteConfig {
  AppConfig get appConfig {
    final algolia = jsonDecode(getString('algolia')) as Map<String, dynamic>;
    return AppConfig(
      algolia: AlgoliaConfig.fromJson(algolia),
    );
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:score/app.dart';
import 'package:score/features/auth/auth_feature.dart';
import 'package:score/features/logging/logging_feature.dart';
import 'package:score/shared/dependency_management/feature_manager.dart';
import 'package:score/shared/dependency_management/get_it_extensions.dart';
import 'package:score/shared/dependency_management/get_it_provider.dart';
import 'package:score/shared/firebase/firebase_feature.dart';
import 'package:score/shared/router/routing_feature.dart';

Future<void> main() async {
  final getIt = GetIt.asNewInstance();
  runZonedGuarded(() async => run(getIt), (error, stackTrace) {
    final logger = getLogger(getIt);
    logger.wtf('Error in main: $error', error, stackTrace);
  });
}

Future<void> run(GetIt getIt) async {
  final featureManager = FeatureManager(
    features: [
      const LoggingFeature(),
      AuthFeature(),
      const FirebaseFeature(),
      const RoutingFeature(),
      // const UploadFeature(),
    ],
    getIt: getIt,
  )..registerTypes();

  await featureManager.install();

  runApp(
    GetItProvider(
      getIt: getIt,
      child: const App(),
    ),
  );
}

Logger getLogger(GetIt getIt) {
  final getItLogger = getIt.tryGetLogger('main');
  if (getItLogger != null) {
    return getItLogger;
  }
  final newLogger = Logger('main');
  PrintSink(PrettyFormatter()).listenTo(newLogger.onRecord);
  return newLogger;
}

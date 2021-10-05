import 'dart:async';
import 'dart:developer';

import 'package:core/core.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'dc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final getIt = GetIt.instance;
  await getIt.init();
  runZonedGuarded(() async {
    // await getIt.firestore.enablePersistence();
    final user = await getIt.userRepository.user();
    if (user == null) {
      getIt.logger.i('user is not logged in');
    } else if (!user.accessLevels.application) {
      getIt.logger.i('user does not yet have access');
    } else {
      getIt.logger.i('welcome back');
    }

    runApp(App(getIt: getIt, user: user));
  }, (error, stackTrace) {
    try {
      getIt.prettyLogger.e('App crash', error, stackTrace);
    } catch (e) {
      log('App crash + log crash: $error at \r\n$stackTrace');
    }
  });
}

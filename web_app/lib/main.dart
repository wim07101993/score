import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/logging/logging_feature.dart';
import 'package:score/shared/dependency_management/feature_manager.dart';

final getIt = GetIt.asNewInstance();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final featureManager = FeatureManager(
    features: [
      const LoggingFeature(),
    ],
    getIt: getIt,
  )..registerTypes();

  await featureManager.install();

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // final collection = FirebaseFirestore.instance.collection("scoresx");
  // final json = await rootBundle.loadString('assets/scoresx.json');
  // final scores = jsonDecode(json) as List<dynamic>;
  // for (final score in scores.whereType<Map<String, dynamic>>()) {
  //   print('adding score ${score["title"]}');
  //   await collection.add(score);
  // }
}

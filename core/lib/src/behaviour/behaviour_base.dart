import 'package:firebase_performance/firebase_performance.dart';
import 'package:logger/logger.dart';

import 'behaviour_mixin.dart';

abstract class BehaviourBase with BehaviourMixin {
  BehaviourBase(BehaviourDependencies dependencies)
      : firebasePerformance = dependencies.firebasePerformance,
        logger = dependencies.logger;

  @override
  final FirebasePerformance firebasePerformance;
  @override
  final Logger logger;
}

class BehaviourDependencies {
  BehaviourDependencies(this.logger, this.firebasePerformance);

  final Logger logger;
  final FirebasePerformance firebasePerformance;
}

// Generated by Hive CE
// Do not modify
// Check in to version control

import 'package:hive_ce/hive.dart';
import 'package:score/shared/hive/hive_adapters.dart';

extension HiveRegistrar on HiveInterface {
  void registerAdapters() {
    registerAdapter(CreatorsAdapter());
    registerAdapter(MovementAdapter());
    registerAdapter(ScoreAdapter());
    registerAdapter(WorkAdapter());
  }
}

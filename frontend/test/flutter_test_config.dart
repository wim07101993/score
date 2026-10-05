import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:score/features/observability/get_it.dart';

/// Runs around every test file: what the app logs goes through a logger it
/// gets from GetIt, so the loggers are there for every test, whatever else it
/// registers.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GetIt.I.registerLogging();
  await testMain();
}

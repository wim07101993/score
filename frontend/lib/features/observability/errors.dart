import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/observability/get_it.dart';

void catchUncaughtErrors() {
  FlutterError.onError = (details) {
    GetIt.I.logger('flutter-error').severe('$details', details, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    GetIt.I.logger('platform-error').severe('$error', error, stackTrace);
    return false;
  };
}

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Logs what Flutter and the platform catch that nothing else did: on
/// [flutterErrors] what went wrong while building or drawing, and on
/// [platformErrors] what was thrown outside of that.
void catchUncaughtErrors({
  required Logger flutterErrors,
  required Logger platformErrors,
}) {
  FlutterError.onError = (details) {
    flutterErrors.severe('$details', details, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    platformErrors.severe('$error', error, stackTrace);
    return false;
  };
}

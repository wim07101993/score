import 'dart:async';

import 'package:logging/logging.dart';

/// Starts work and does not wait for it, saying so when it fails.
///
/// Not `dart:async`'s `unawaited`, which leaves a failure to nobody: work that
/// is started and left — a sync behind a page that is already drawn, a
/// bookkeeping write — is work nothing else is listening to, so this is where
/// its failure is heard. A behaviour that is started this way never throws;
/// what goes wrong in it is heard by its monitor.
class const Background({
  required final Logger logger,
}) {
  void call(FutureOr<Object?> work) {
    unawaited(
      Future.value(work).catchError((Object error, StackTrace stackTrace) {
        logger.severe(
            'work left to run in the background failed', error, stackTrace);
        return null;
      }),
    );
  }
}

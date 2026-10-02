import 'package:logging/logging.dart';

final _log = Logger('Background');

/// Starts [work] and does not wait for it, saying so when it fails.
///
/// Not `dart:async`'s `unawaited`, which leaves a failure to nobody: work that
/// is started and left — a sync behind a page that is already drawn, a
/// bookkeeping write — is work nothing else is listening to, so this is where
/// its failure is heard.
void inTheBackground(Future<void> work) {
  work.catchError((Object error, StackTrace stackTrace) {
    _log.severe('work left to run in the background failed', error, stackTrace);
  });
}

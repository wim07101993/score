/// Where what the app logs goes.
///
/// Every part of the app logs to a [Logger] of its own, named after it, and
/// all of them end up here: in the console, and in [logs], which the logs page
/// in the settings shows. The console is where a developer looks; the page is
/// where a player looks when something does not sync and somebody asks them
/// what the app says — on a phone in a rehearsal room, there is no console.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';

/// What was logged since the app started, the last
/// [LogsController.maxLogCount] of it. Kept in memory only: what is wanted is
/// what just happened, and a log written down would be a log to clean up.
final logs = LogsController();

/// Sends everything that is logged to the console and to [logs], and logs what
/// nothing caught.
///
/// Called once, before anything logs.
void startLogging() {
  Logger.root.level = Level.ALL;
  final records = Logger.root.onRecord;

  LogsControllerLogSink(controller: logs).listenTo(records);
  // Everything while developing; in a release, what someone might have to act
  // on, rather than every step of every sync.
  PrintSink(
    SimpleFormatter(),
    const LogFilter.level(kReleaseMode ? Level.INFO : Level.ALL),
  ).listenTo(records);

  final uncaught = Logger('Uncaught');
  FlutterError.onError = (details) {
    uncaught.severe(details.exceptionAsString(), details.exception,
        details.stack);
    // Still shown the way Flutter shows it, with the widget it happened in.
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    uncaught.severe('$error', error, stackTrace);
    // Not handled: whatever the platform does with an error nothing caught,
    // it still does.
    return false;
  };
}

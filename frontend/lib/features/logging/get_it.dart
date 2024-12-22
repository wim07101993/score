import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:fox_logging/src/sink/dev_log_sink.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/logging/behaviour_monitor.dart';
import 'package:score/features/logging/logging_behaviour_track.dart';

void registerLogging() {
  recordStackTraceAtLevel = Level.SEVERE;
  Logger.root.level = Level.ALL;

  GetIt.I.registerFactoryParam<Logger, String, dynamic>(
    (loggerName, _) => Logger(loggerName),
  );
  GetIt.I.registerLazySingleton(
    () => DevLogSink(),
    dispose: (sink) => sink.dispose(),
  );
  GetIt.I.registerFactory<LogSink>(() => GetIt.I<DevLogSink>());

  GetIt.I.registerFactoryParam<BehaviourTrack, BehaviourMixin, dynamic>(
    (behaviour, _) => LoggingBehaviourTrack(
      behaviour,
      logger: GetIt.I.logger(behaviour.tag),
    ),
  );
  GetIt.I.registerLazySingleton<BehaviourMonitor>(
    () => const GetItBehaviourMonitor(),
  );
}

extension LoggingGetItExtensions on GetIt {
  Logger logger(String loggerName) => get<Logger>(param1: loggerName);
}

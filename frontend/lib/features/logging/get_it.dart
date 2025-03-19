import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:score/features/logging/behaviour_monitor.dart';
import 'package:score/features/logging/db_log_sink.dart';
import 'package:score/features/logging/logging_behaviour_track.dart';

void registerLogging() {
  recordStackTraceAtLevel = Level.SEVERE;
  Logger.root.level = Level.ALL;

  GetIt.I.registerFactoryParam<Logger, String, dynamic>(
    (loggerName, _) => Logger(loggerName),
  );

  GetIt.I.registerLazySingleton(
    () => PrintSink(
      LevelDependentFormatter(
        defaultFormatter: SimpleFormatter(),
        severe: PrettyFormatter(),
        shout: PrettyFormatter(),
      ),
    ),
    dispose: (sink) => sink.dispose(),
  );
  GetIt.I.registerLazySingleton(
    () => DevLogSink(),
    dispose: (sink) => sink.dispose(),
  );

  GetIt.I.registerLazySingleton(() => LogsController());
  GetIt.I.registerLazySingleton(
    () => DbLogSink(
      database: GetIt.I.getAsync(),
    ),
  );
  GetIt.I.registerLazySingletonAsync(() async {
    final hive = await GetIt.I.getAsync<HiveInterface>();
    return hive.openLazyBox<LogRecord>('logsBox');
  });
  GetIt.I.registerLazySingleton<LogsControllerLogSink>(
    () => LogsControllerLogSink(controller: GetIt.I()),
  );

  GetIt.I.registerLazySingleton<LogSink>(
    () => MultiLogSink(
      [
        GetIt.I<PrintSink>(),
        GetIt.I<DbLogSink>(),
        GetIt.I<LogsControllerLogSink>(),
      ],
    ),
  );

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

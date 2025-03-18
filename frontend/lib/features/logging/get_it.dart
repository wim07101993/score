import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/features/logging/behaviour_monitor.dart';
import 'package:score/features/logging/db_extensions.dart';
import 'package:score/features/logging/db_log_sink.dart';
import 'package:score/features/logging/logging_behaviour_track.dart';
import 'package:score/features/logging/logs_controller_log_sink.dart';

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

  GetIt.I.registerLazySingletonAsync<LogsController>(() async {
    final database = await GetIt.I.getAsync<LibsqlClient>();
    final logs = await database.getLogs().take(1000).toList();
    return LogsController()..addAllLogs(logs);
  });
  GetIt.I.registerLazySingleton(
    () => DbLogSink(
      database: GetIt.I.getAsync(),
    ),
  );
  GetIt.I.registerLazySingleton<FutureLogsControllerLogSink>(
    () => FutureLogsControllerLogSink(controller: GetIt.I.getAsync()),
  );

  GetIt.I.registerLazySingleton<LogSink>(
    () => MultiLogSink(
      [
        GetIt.I<DevLogSink>(),
        GetIt.I<DbLogSink>(),
        GetIt.I<FutureLogsControllerLogSink>(),
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

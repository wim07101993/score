import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
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

  // GetIt.I.registerLazySingleton(
  //   () => HiveLogSink(
  //     box: GetIt.I.getAsync<Box<LogRecord>>(),
  //   ),
  //   dispose: (sink) => sink.dispose(),
  // );
  // GetIt.I.registerLazySingletonAsync<HiveInterface>(() async {
  //   Hive.registerAdapter(const LogRecordAdapter());
  //   Hive.registerAdapter(const LogLevelAdapter());
  //   Hive.registerAdapter(const StackTraceAdapter());
  //   Hive.registerAdapter(BehaviourLogObjectAdapter());
  //   await Hive.initFlutter();
  //   return Hive;
  // });
  // GetIt.I.registerLazySingletonAsync<Box<LogRecord>>(
  //   () async {
  //     final hive = await GetIt.I.getAsync<HiveInterface>();
  //     return hive.openBox<LogRecord>('logs');
  //   },
  //   dispose: (box) async {
  //     await box.flush();
  //     await box.close();
  //   },
  // );

  // GetIt.I.registerLazySingletonAsync<LogsController>(() async {
  //   final box = await GetIt.I.getAsync<Box<LogRecord>>();
  //   return LogsController()..addAllLogs(box.values);
  // });
  // GetIt.I.registerLazySingleton<FutureLogsControllerLogSink>(
  //   () => FutureLogsControllerLogSink(controller: GetIt.I.getAsync()),
  // );

  GetIt.I.registerLazySingleton<LogSink>(
    () => MultiLogSink(
      [
        GetIt.I<DevLogSink>(),
        // GetIt.I<HiveLogSink>(),
        // GetIt.I<FutureLogsControllerLogSink>(),
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

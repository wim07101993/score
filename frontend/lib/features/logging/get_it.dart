import 'package:behaviour/behaviour.dart';
import 'package:cbl/cbl.dart' hide Logger;
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/logging/behaviour_monitor.dart';
import 'package:score/features/logging/couch_db_log_sink.dart';
import 'package:score/features/logging/logging_behaviour_track.dart';
import 'package:score/features/logging/logs_controller_log_sink.dart';

const String logsCollectionInstance = 'logs-collection';

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

  GetIt.I.registerLazySingletonAsync<Collection>(
    () async {
      final database = await GetIt.I.getAsync<Database>();
      return database.createCollection(logsCollectionInstance);
    },
    instanceName: logsCollectionInstance,
  );
  GetIt.I.registerLazySingleton(
    () => CouchDbLogSink(
      database: GetIt.I.getAsync<Collection>(
        instanceName: logsCollectionInstance,
      ),
    ),
    dispose: (sink) => sink.dispose(),
  );

  GetIt.I.registerLazySingletonAsync<LogsController>(() async {
    final logsCollection = await GetIt.I.getAsync<Collection>(
      instanceName: logsCollectionInstance,
    );
    final logs = await _getLogRecords(logsCollection);
    return LogsController()..addAllLogs(logs);
  });
  GetIt.I.registerLazySingleton<FutureLogsControllerLogSink>(
    () => FutureLogsControllerLogSink(controller: GetIt.I.getAsync()),
  );

  GetIt.I.registerLazySingleton<LogSink>(
    () => MultiLogSink(
      [
        GetIt.I<DevLogSink>(),
        // GetIt.I<CouchDbLogSink>(),
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

Future<List<LogRecord>> _getLogRecords(Collection logsCollection) async {
  final logResults = await const QueryBuilder()
      .select(SelectResult.all())
      .from(DataSource.collection(logsCollection))
      .orderBy(
        Ordering.property(LogRecordPropertyNames.sequenceNumber).descending(),
      )
      .limit(Expression.integer(1000))
      .execute();

  return logResults.allTypedResults();
}

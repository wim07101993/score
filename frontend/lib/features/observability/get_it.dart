import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/observability/behaviour_monitor.dart';
import 'package:score/features/observability/storage/logs_store.dart';
import 'package:score/features/observability/stored_logs.dart';
import 'package:score/storage/databases.dart';

enum LoggerName({required final String name}) {
  root(name: 'root'),
  app(name: 'score'),
}

extension ObservabilityGetItExtensions on GetIt {
  void registerLogging() {
    registerFactory<LogSinkMixin>(() => get<PrintSink>());
    registerLazySingleton(() => PrintSink(get<LogRecordFormatter>()));
    registerLazySingleton<LogRecordFormatter>(() {
      final pretty = PrettyFormatter();
      return LevelDependentFormatter(
        defaultFormatter: SimpleFormatter(),
        severe: pretty,
        shout: pretty,
      );
    });

    registerFactoryParam<Logger, String, dynamic>((name, _) {
      return _loggerFactory(this, name);
    });

    registerLazySingleton(() => LogsController());

    registerLazySingleton<BehaviourMonitor>(
      () => LoggingBehaviourMonitor(logger: logger),
    );
  }

  /// Keeps what is logged in the local store as well: see [StoredLogSink].
  void registerLogStorage() {
    registerLazySingleton(
      () => StoredLogSink(
        store: getAsync<Databases>()
            .then((databases) => LogsStore(database: databases.data)),
        logs: get<LogsController>(),
      ),
    );
  }

  Logger logger(String name) => get<Logger>(param1: name);
}

var _hasSetUpRootLogger = false;

Logger _loggerFactory(GetIt getIt, String loggerName) {
  if (!_hasSetUpRootLogger) {
    _setUpRootLogger(getIt);
  }
  if (loggerName == LoggerName.root.name) {
    return Logger.root;
  }
  if (loggerName == LoggerName.app.name) {
    return Logger(LoggerName.app.name);
  }
  return Logger('${LoggerName.app.name}.$loggerName');
}

void _setUpRootLogger(GetIt getIt) {
  _hasSetUpRootLogger = true;
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.WARNING;
  Logger(LoggerName.app.name).level = Level.ALL;

  final records = Logger.root.onRecord;
  getIt<LogSinkMixin>().listenTo(records);
  LogsControllerLogSink(controller: getIt<LogsController>()).listenTo(records);
  if (getIt.isRegistered<StoredLogSink>()) {
    getIt<StoredLogSink>().listenTo(records);
  }
}

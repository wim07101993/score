import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/observability/stored_logs.dart';
import 'package:score/features/sembast/local_store.dart';

enum LoggerName {
  root('root'),
  app('score');

  const LoggerName(this.name);

  final String name;
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
  }

  /// Keeps what is logged in the local store as well: see [StoredLogSink].
  void registerLogStorage() {
    registerLazySingleton(
      () => StoredLogSink(getAsync<LocalStore>(), get<LogsController>()),
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

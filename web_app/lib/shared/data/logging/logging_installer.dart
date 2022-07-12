import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/app_get_it_extensions.dart';
import 'package:score/shared/data/logging/hive_log_sink.dart';

class LoggingInstaller implements Installer {
  const LoggingInstaller();

  @override
  Future<void> initialize(GetIt getIt) {
    Logger.root.level = Level.ALL;
    hierarchicalLoggingEnabled = true;
    getIt.logger('getIt').i('initialized logging');
    return Future.value();
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton(
        () => HiveLogSink(guidGenerator: getIt(), hive: getIt()));
    getIt.registerLazySingleton<LogSink>(() {
      final simpleFormatter = SimpleFormatter();
      final prettyFormatter = PrettyFormatter();
      return MultiLogSink([
        PrintSink(LevelDependentFormatter(
          defaultFormatter: simpleFormatter,
          severe: prettyFormatter,
          shout: prettyFormatter,
        )),
        // DevLogSink(),
        getIt<HiveLogSink>(),
      ]);
    });
    getIt.registerFactoryParam((String loggerName, p2) {
      final logger = Logger(loggerName);
      getIt<LogSink>().listenTo(logger.onRecord);
      return logger;
    });
  }
}

import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:get_it/get_it.dart';
import 'package:score/shared/dependency_management/feature.dart';

class LoggingFeature extends Feature {
  const LoggingFeature();

  @override
  void registerTypes(GetIt getIt) {
    getIt.registerFactoryParam<Logger, String, dynamic>(
      (loggerName, _) => _loggerFactory(getIt, loggerName),
    );
    getIt.registerLazySingleton<LogSink>(() {
      final prettyFormatter = PrettyFormatter();
      return PrintSink(
        LevelDependentFormatter(
          defaultFormatter: SimpleFormatter(),
          severe: prettyFormatter,
          shout: prettyFormatter,
        ),
      );
    });
  }

  Logger _loggerFactory(GetIt getIt, String loggerName) {
    final instanceName = '$loggerName-logger';
    if (getIt.isRegistered<Logger>(instanceName: instanceName)) {
      return getIt.get<Logger>(instanceName: instanceName);
    } else {
      final logger = Logger.detached(loggerName)..level = Level.ALL;
      getIt.registerSingleton<Logger>(
        logger,
        instanceName: instanceName,
        dispose: (instance) => instance.clearListeners(),
      );
      getIt<LogSink>().listenTo(logger.onRecord);
      return logger;
    }
  }
}

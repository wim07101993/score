import 'package:behaviour/behaviour.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:get_it/get_it.dart';

class BehaviourMonitorImpl<T extends BehaviourTrack>
    implements BehaviourMonitor {
  const BehaviourMonitorImpl({
    required this.getIt,
  });

  final GetIt getIt;

  @override
  BehaviourTrack? createBehaviourTrack(BehaviourMixin behaviour) {
    return getIt<T>(param1: behaviour);
  }
}

class StandardBehaviourTrack implements BehaviourTrack {
  const StandardBehaviourTrack({
    required this.behaviour,
    required this.logger,
  });

  final Logger logger;

  @override
  final BehaviourMixin behaviour;

  @override
  void addAttribute(String key, Object value) {}

  @override
  void end() => logger.v('finished ${behaviour.description}');

  @override
  void start() => logger.v('start ${behaviour.description}');

  @override
  void stopWithError(Object error, StackTrace stackTrace) {
    logger.wtf(
      'an error happened while ${behaviour.description}',
      error,
      stackTrace,
    );
  }

  @override
  void stopWithException(Exception exception, StackTrace stackTrace) {
    logger.e(
      'an exception happened while ${behaviour.description}',
      exception,
      stackTrace,
    );
  }
}

import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';

class LoggingBehaviourTrack extends BehaviourTrack {
  LoggingBehaviourTrack({
    required BehaviourMixin behaviour,
    required this.logger,
  }) : super(behaviour);

  final Logger logger;

  @override
  void addAttribute(String key, Object value) {
    logger.v('--- add attribute $key: $value');
  }

  @override
  void end() {
    logger.i('done ${behaviour.description}');
  }

  @override
  void start() {
    logger.i('start ${behaviour.description}');
  }

  @override
  void stopWithError(Object error, StackTrace stackTrace) {
    logger.e('error while ${behaviour.description}', error, stackTrace);
  }

  @override
  void stopWithException(Exception exception, StackTrace stackTrace) {
    logger.e('exception while ${behaviour.description}', exception, stackTrace);
  }
}

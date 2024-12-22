import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';

class LoggingBehaviourTrack extends BehaviourTrack {
  LoggingBehaviourTrack(
    super.behaviour, {
    required this.logger,
  });

  final Logger logger;

  final Map<String, Object> attributes = {};

  @override
  void addAttribute(String key, Object value) => attributes[key] = value;

  @override
  void end() {
    attributes['message'] = 'done ${behaviour.description}';
    logger.v(attributes);
    attributes.clear();
  }

  @override
  void start() {
    attributes['message'] = 'start ${behaviour.description}';
    logger.v(attributes);
    attributes.clear();
  }

  @override
  void stopWithError(Object error, StackTrace stackTrace) {
    attributes['message'] = 'error while ${behaviour.description}';
    logger.wtf(attributes, error, stackTrace);
    attributes.clear();
  }

  @override
  void stopWithException(Exception exception, StackTrace stackTrace) {
    attributes['message'] = 'exception while ${behaviour.description}';
    logger.severe(attributes, exception, stackTrace);
    attributes.clear();
  }
}

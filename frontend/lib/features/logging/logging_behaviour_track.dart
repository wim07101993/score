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
    logger.v(
      BehaviourLogObject(
        message: 'done ${behaviour.description}',
        attributes: attributes.isNotEmpty ? attributes : null,
      ),
    );
    attributes.clear();
  }

  @override
  void start() {
    logger.v(
      BehaviourLogObject(
        message: 'start ${behaviour.description}',
        attributes: attributes.isNotEmpty ? attributes : null,
      ),
    );
    attributes.clear();
  }

  @override
  void stopWithError(Object error, StackTrace stackTrace) {
    logger.wtf(
      BehaviourLogObject(
        message: 'error while ${behaviour.description}',
        attributes: attributes.isNotEmpty ? attributes : null,
      ),
      error,
      stackTrace,
    );
    attributes.clear();
  }

  @override
  void stopWithException(Exception exception, StackTrace stackTrace) {
    logger.severe(
      BehaviourLogObject(
        message: 'exception while ${behaviour.description}',
        attributes: attributes.isNotEmpty ? attributes : null,
      ),
      exception,
      stackTrace,
    );
    attributes.clear();
  }
}

class BehaviourLogObject {
  const BehaviourLogObject({
    required this.message,
    required this.attributes,
  });

  final String message;
  final Map<String, dynamic>? attributes;

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'attributes': attributes,
    };
  }
}

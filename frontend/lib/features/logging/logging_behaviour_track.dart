import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:score/shared/hive_type_ids.dart';

part 'logging_behaviour_track.g.dart';

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
      _BehaviourLogObject(
        message: 'done ${behaviour.description}',
        attributes: attributes.isNotEmpty ? attributes : null,
      ),
    );
    attributes.clear();
  }

  @override
  void start() {
    logger.v(
      _BehaviourLogObject(
        message: 'start ${behaviour.description}',
        attributes: attributes.isNotEmpty ? attributes : null,
      ),
    );
    attributes.clear();
  }

  @override
  void stopWithError(Object error, StackTrace stackTrace) {
    logger.wtf(
      _BehaviourLogObject(
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
      _BehaviourLogObject(
        message: 'exception while ${behaviour.description}',
        attributes: attributes.isNotEmpty ? attributes : null,
      ),
      exception,
      stackTrace,
    );
    attributes.clear();
  }
}

@HiveType(typeId: HiveTypeIds.behaviourLogObject)
class _BehaviourLogObject {
  const _BehaviourLogObject({
    required this.message,
    required this.attributes,
  });

  @HiveField(0)
  final String message;
  @HiveField(1)
  final Map<String, dynamic>? attributes;

  @override
  String toString() => message;
}

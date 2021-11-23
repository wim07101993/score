import '../../core.dart';

abstract class BehaviourTrack {
  const BehaviourTrack(this.behaviour);

  final BehaviourMixin behaviour;

  void start();
  void end();
  void stopWithException(Exception exception, StackTrace stackTrace);
  void stopWithError(Object error, StackTrace stackTrace);
}

class BehaviourLoggerTrack extends BehaviourTrack {
  const BehaviourLoggerTrack(
    this.logger,
    BehaviourMixin behaviour,
  ) : super(behaviour);

  final Logger logger;

  @override
  void end() {
    logger.v('${behaviour.tag}: Finished ${behaviour.description}');
  }

  @override
  void start() {
    logger.v('${behaviour.tag}: ${behaviour.description}');
  }

  @override
  void stopWithError(Object error, StackTrace stackTrace) {
    logger.e(
      '${behaviour.tag}: An error happened while ${behaviour.description}',
      error,
      stackTrace,
    );
  }

  @override
  void stopWithException(Exception exception, StackTrace stackTrace) {
    logger.e(
      '${behaviour.tag}: An exception happened while ${behaviour.description}',
      exception,
      stackTrace,
    );
  }
}

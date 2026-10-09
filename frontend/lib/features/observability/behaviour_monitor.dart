import 'package:behaviour/behaviour.dart';
import 'package:logging/logging.dart';

/// Logs what every behaviour does, under a logger named after it: that it
/// started, that it finished, and why when it did not.
///
/// A behaviour never throws — what went wrong is handed back to whoever called
/// it — so this is where a failure is heard even when the caller has nothing to
/// say about it.
class const LoggingBehaviourMonitor({
  required final Logger Function(String name) logger,
}) implements BehaviourMonitor {
  @override
  BehaviourTrack createBehaviourTrack(BehaviourMixin behaviour) =>
      _LoggingTrack(behaviour: behaviour, log: logger(behaviour.tag));
}

class _LoggingTrack({
  required BehaviourMixin behaviour,
  required final Logger log,
}) extends BehaviourTrack {
  this : super(behaviour);

  final Map<String, Object> _attributes = {};

  String get _withAttributes =>
      _attributes.isEmpty ? '' : ' ${_attributes.entries.join(', ')}';

  @override
  void start() => log.finer('${behaviour.description}$_withAttributes');

  @override
  void end() => log.finer('done ${behaviour.description}');

  @override
  void stopWithException(Exception exception, StackTrace stackTrace) =>
      log.warning(
        'failed ${behaviour.description}$_withAttributes',
        exception,
        stackTrace,
      );

  @override
  void stopWithError(Object error, StackTrace stackTrace) => log.severe(
    'failed ${behaviour.description}$_withAttributes',
    error,
    stackTrace,
  );

  @override
  void addAttribute(String key, Object value) => _attributes[key] = value;
}

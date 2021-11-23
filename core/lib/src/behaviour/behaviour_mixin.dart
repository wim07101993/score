import 'dart:async';

import 'package:core/src/monitor/behaviour_track.dart';
import 'package:core/src/monitor/monitor.dart';

import 'exception_or.dart';

typedef Action<TOut> = Future<ExceptionOr<TOut>> Function();

mixin BehaviourMixin {
  Monitor get monitor;
  BehaviourTrack? _track;
  BehaviourTrack get track;
  String get description;
  String get tag => runtimeType.toString();

  Future<ExceptionOr<TOut>> executeAction<TOut>(Action<TOut> action) async {
    try {
      _track = monitor.createBehaviourTrack(this);
      final either = await action();
      _track?.end();
      return either;
    } on Exception catch (exception, stackTrace) {
      _track?.stopWithException(exception, stackTrace);
      return Failed(exception);
    } catch (error, stackTrace) {
      _track?.stopWithError(error, stackTrace);
      return Failed(await onError(error, stackTrace));
    } finally {
      _track = null;
    }
  }

  FutureOr<Exception> onError(Object e, StackTrace stacktrace);
}

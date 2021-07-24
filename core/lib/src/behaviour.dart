import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'failure.dart';
import 'failure_or.dart';

mixin BehaviourMixin {
  @protected
  Logger get errorLogger;
  @protected
  @visibleForTesting
  String? get description => null;

  @protected
  @visibleForTesting
  Future<FailureOr<TOut>> executeAction<TOut>(
    Future<FailureOr<TOut>> Function() action,
  ) async {
    try {
      return await action();
    } catch (e, stackTrace) {
      await logException(e, stackTrace);
      return Failed(await onFailed(e, stackTrace));
    }
  }

  @protected
  Future<void> logException(dynamic e, StackTrace stackTrace) {
    final description = this.description;
    if (description == null) {
      errorLogger.e('An error happened', e, stackTrace);
    } else {
      errorLogger.e('An error happened on $description', e, stackTrace);
    }
    return Future.value();
  }

  @protected
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace);
}

abstract class Behaviour<TIn, TOut> with BehaviourMixin {
  const Behaviour({
    required this.errorLogger,
  });

  @override
  final Logger errorLogger;
  @override
  String? get description => null;

  Future<FailureOr<TOut>> call(TIn input) {
    return executeAction(() async => Success(await action(input)));
  }

  @protected
  Future<TOut> action(TIn input);
}

abstract class BehaviourWithoutInput<T> with BehaviourMixin {
  const BehaviourWithoutInput({
    required this.errorLogger,
  });

  @override
  final Logger errorLogger;
  @override
  String? get description => null;

  @protected
  Future<FailureOr<T>> call() {
    return executeAction(() async => Success(await action()));
  }

  @protected
  Future<T> action();
}

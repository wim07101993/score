part of 'behaviour_test.dart';

abstract class _FailureGenerator {
  Future<Failure> call(dynamic e, StackTrace stackTrace);
}

abstract class _Action<TIn, TOut> {
  Future<TOut> call(TIn input);
}

abstract class _ActionWithoutInput<TOut> {
  Future<TOut> call();
}

class MockFailureGenerator extends Mock implements _FailureGenerator {}

class MockAction<TIn, TOut> extends Mock implements _Action<TIn, TOut> {}

class MockActionWithoutInput<T> extends Mock implements _ActionWithoutInput<T> {
}

class _WithBehaviourMixin with BehaviourMixin {
  const _WithBehaviourMixin(
    this.errorLogger,
    this.failureGenerator,
    this.description,
  );

  @override
  final Logger errorLogger;
  @override
  final String? description;
  final Future<Failure> Function(dynamic, StackTrace) failureGenerator;

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    return failureGenerator(e, stacktrace);
  }
}

class _Behaviour<TIn, TOut> extends Behaviour<TIn, TOut> {
  const _Behaviour({
    required Logger errorLogger,
    required this.failureGenerator,
    required this.onAction,
    required this.description,
  }) : super(errorLogger: errorLogger);

  @override
  final String? description;
  final Future<Failure> Function(dynamic, StackTrace) failureGenerator;
  final Future<TOut> Function(TIn input) onAction;

  @override
  Future<TOut> action(TIn input) => onAction(input);

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    return failureGenerator(e, stacktrace);
  }
}

class _BehaviourWithoutInput<T> extends BehaviourWithoutInput<T> {
  const _BehaviourWithoutInput({
    required Logger errorLogger,
    required this.failureGenerator,
    required this.onAction,
    required this.description,
  }) : super(errorLogger: errorLogger);

  @override
  final String? description;
  final Future<Failure> Function(dynamic, StackTrace) failureGenerator;
  final Future<T> Function() onAction;

  @override
  Future<T> action() => onAction();

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    return failureGenerator(e, stacktrace);
  }
}

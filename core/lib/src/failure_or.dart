import 'failure.dart';

abstract class FailureOr<T> {
  const FailureOr();

  TResult fold<TResult>(
    TResult Function(Failure failure) ifFailure,
    TResult Function(T value) ifSuccess,
  );
}

class Failed<T> extends FailureOr<T> {
  const Failed(this.failure);

  final Failure failure;

  @override
  TResult fold<TResult>(
    TResult Function(Failure failure) ifFailure,
    TResult Function(T value) ifSuccess,
  ) {
    return ifFailure(failure);
  }

  @override
  bool operator ==(Object other) => other is Failed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode ^ super.hashCode;
}

class Success<T> extends FailureOr<T> {
  const Success(this.value);

  final T value;

  @override
  TResult fold<TResult>(
    TResult Function(Failure failure) ifFailure,
    TResult Function(T value) ifSuccess,
  ) {
    return ifSuccess(value);
  }

  @override
  bool operator ==(Object other) => other is Success && other.value == value;

  @override
  int get hashCode => value.hashCode ^ super.hashCode;
}

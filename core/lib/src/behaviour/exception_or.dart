abstract class ExceptionOr<T> {
  const ExceptionOr();

  TResult fold<TResult>(
    TResult Function(Exception exception) ifException,
    TResult Function(T value) ifSuccess,
  );
}

class Failed<T> extends ExceptionOr<T> {
  const Failed(this.exception);

  final Exception exception;

  @override
  TResult fold<TResult>(
    TResult Function(Exception exception) ifException,
    TResult Function(T value) ifSuccess,
  ) {
    return ifException(exception);
  }

  @override
  bool operator ==(Object other) =>
      other is Failed && other.exception == exception;

  @override
  int get hashCode => exception.hashCode ^ super.hashCode;
}

class Success<T> extends ExceptionOr<T> {
  const Success(this.value);

  final T value;

  @override
  TResult fold<TResult>(
    TResult Function(Exception exception) ifException,
    TResult Function(T value) ifSuccess,
  ) {
    return ifSuccess(value);
  }

  @override
  bool operator ==(Object other) => other is Success && other.value == value;

  @override
  int get hashCode => value.hashCode ^ super.hashCode;
}

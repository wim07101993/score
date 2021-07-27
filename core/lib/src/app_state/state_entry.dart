abstract class StateEntry<T> implements ReadOnlyStateEntry<T> {
  Future<void> set(T value);
}

abstract class ReadOnlyStateEntry<T> {
  T call();
  Stream<T> get changes;
}

abstract class FutureStateEntry<T> implements FutureReadOnlyStateEntry<T> {
  Future<void> set(T value);
}

abstract class FutureReadOnlyStateEntry<T> {
  Future<T> call();
  Stream<T> get changes;
}

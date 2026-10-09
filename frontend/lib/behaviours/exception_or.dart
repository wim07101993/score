import 'package:behaviour/behaviour.dart';

extension ExceptionOrValue<T> on ExceptionOr<T> {
  /// What the behaviour answered with, or what went wrong thrown: for a caller
  /// that cannot go on without the answer, like the app starting.
  T orThrow() => switch (this) {
    Success(:final value) => value,
    Failed(:final reason) => throw reason,
  };

  /// What the behaviour answered with, or null when it failed.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failed() => null,
  };
}

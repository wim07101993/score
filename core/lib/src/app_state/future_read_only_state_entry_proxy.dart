import 'package:core/src/app_state/state_entry.dart';

class FutureReadOnlyStateEntryProxy<T> implements FutureReadOnlyStateEntry<T> {
  const FutureReadOnlyStateEntryProxy({
    required Future<T> Function() call,
    required Stream<T> Function() changes,
  })  : _call = call,
        _changes = changes;

  final Future<T> Function() _call;
  final Stream<T> Function() _changes;

  @override
  Future<T> call() => _call();

  @override
  Stream<T> get changes => _changes();
}

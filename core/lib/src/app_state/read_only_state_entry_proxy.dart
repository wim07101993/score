import 'package:core/src/app_state/state_entry.dart';

class ReadOnlyStateEntryProxy<T> implements ReadOnlyStateEntry<T> {
  const ReadOnlyStateEntryProxy({
    required T Function() call,
    required Stream<T> Function() changes,
  })  : _call = call,
        _changes = changes;

  final T Function() _call;
  final Stream<T> Function() _changes;

  @override
  T call() => _call();

  @override
  Stream<T> get changes => _changes();
}

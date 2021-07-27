import 'state_entry.dart';

class ConvertingStateEntry<T, TStorage> implements StateEntry<T> {
  const ConvertingStateEntry({
    required this.fromEntry,
    required this.convertToStorage,
    required this.convertFromStorage,
  });

  final StateEntry<TStorage> fromEntry;
  final T Function(TStorage) convertFromStorage;
  final TStorage Function(T) convertToStorage;

  @override
  T call() => convertFromStorage(fromEntry());

  @override
  Stream<T> get changes => fromEntry.changes.map(convertFromStorage);

  @override
  Future<void> set(T value) => fromEntry.set(convertToStorage(value));
}

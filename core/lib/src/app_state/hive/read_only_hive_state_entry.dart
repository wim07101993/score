import 'package:hive/hive.dart';

import '../state_entry.dart';

class ReadOnlyHiveStateEntry<T> implements ReadOnlyStateEntry<T> {
  const ReadOnlyHiveStateEntry({
    required this.box,
    required this.key,
    required this.defaultValue,
  });

  final Box box;
  final String key;
  final T defaultValue;

  @override
  T call() {
    final value = box.get(key, defaultValue: defaultValue);
    if (value is T) {
      return value;
    }
    if (value != defaultValue) {
      box.put(key, defaultValue);
    }
    return defaultValue;
  }

  @override
  Stream<T> get changes {
    return box.watch(key: key).map((event) {
      final value = event.value;
      return value is T ? value : defaultValue;
    });
  }
}

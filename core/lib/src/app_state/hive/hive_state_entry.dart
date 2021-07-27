import 'package:hive/hive.dart';

import '../state_entry.dart';
import 'read_only_hive_state_entry.dart';

class HiveStateEntry<T> extends ReadOnlyHiveStateEntry<T>
    implements StateEntry<T> {
  const HiveStateEntry({
    required Box box,
    required String key,
    required T defaultValue,
  }) : super(box: box, key: key, defaultValue: defaultValue);

  @override
  Future<void> set(T value) => box.put(key, value);
}

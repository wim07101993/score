import 'package:sembast/sembast.dart';

/// Single values kept by their key — what this device prefers, how it signs
/// in: each feature keeps its own in one of these.
class KeyValueStore({
  required final Database database,

  /// The name of the sembast store the values are kept in.
  required final String name,
}) {
  late final _values = StoreRef<String, String>(name);

  Future<String?> read(String key) => _values.record(key).get(database);

  /// Storing nothing is not the same as storing null: a key that is written
  /// with no value would be read back as the text "null" by whoever asked next.
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _values.record(key).delete(database);
      return;
    }
    await _values.record(key).put(database, value);
  }

  /// One value, again every time it changes. Null while it is not there.
  Stream<String?> watch(String key) =>
      _values.record(key).onSnapshot(database).map((record) => record?.value);
}

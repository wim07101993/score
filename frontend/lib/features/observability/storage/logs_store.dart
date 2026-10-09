import 'package:sembast/sembast.dart';

/// What the app logged, kept so that what led up to a crash can still be read
/// once the app is started again.
class LogsStore({
  required final Database database,
}) {
  final _logs = intMapStoreFactory.store('logs');

  /// Adds one log record after the ones written before it.
  Future<void> write(Map<String, Object?> record) =>
      _logs.add(database, record);

  /// Every log record kept, oldest first.
  Future<List<Map<String, Object?>>> readAll() async {
    final records = await _logs.find(
      database,
      finder: Finder(sortOrders: [SortOrder(Field.key)]),
    );
    return records.map((record) => record.value).toList(growable: false);
  }

  /// Forgets every log record but the last [count].
  Future<void> keepLast(int count) async {
    final keys = await _logs.findKeys(
      database,
      finder: Finder(sortOrders: [SortOrder(Field.key, false)], offset: count),
    );
    await _logs.records(keys).delete(database);
  }
}

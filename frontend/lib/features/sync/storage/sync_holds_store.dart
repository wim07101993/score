import 'package:sembast/sembast.dart';

/// Why what is owed about a set or a collection was not sent, the last time
/// it was tried, by what it is and its id.
class SyncHoldsStore({
  required final Database database,
}) {
  final _holds = stringMapStoreFactory.store('sync_holds');

  /// Says why what is owed about the [kind] with [id] — a set, a collection —
  /// was not sent the last time it was tried, or that it was, with null.
  Future<void> write(String kind, String id, Map<String, Object?>? hold) async {
    final record = _holds.record('$kind/$id');
    if (hold == null) {
      await record.delete(database);
    } else {
      await record.put(database, hold);
    }
  }

  /// Why what is owed about each of the [kind] was not sent, by id, again
  /// every time that changes.
  Stream<Map<String, Map<String, Object?>>> watch(String kind) => _holds
      .query(finder: Finder(filter: _ofKind(kind)))
      .onSnapshots(database)
      .map(
        (records) => {
          for (final record in records)
            record.key.substring(kind.length + 1): record.value,
        },
      );

  /// Forgets why anything of [kind] was not sent: nothing has been tried yet
  /// once the app starts again, and a device that is handed over has nothing
  /// left to send.
  Future<void> forget(String kind) =>
      _holds.delete(database, finder: Finder(filter: _ofKind(kind)));

  Filter _ofKind(String kind) =>
      Filter.custom((record) => '${record.key}'.startsWith('$kind/'));
}

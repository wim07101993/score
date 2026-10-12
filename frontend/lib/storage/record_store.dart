import 'package:sembast/sembast.dart';

class SembastStore<T>({
  required final Database client,
  required final String storeName,
  required final T Function(Map<String, Object?> json) fromJson,
  required final Map<String, Object?> Function(T value) toJson,
  required final String Function(T value) idOf,
  required final String idFieldKey,
}) {
  final store = stringMapStoreFactory.store(storeName);

  Future<List<T>> getAll() async => _valuesOf(await store.find(client));

  Future<List<T>> getElementsWithIds(List<String> ids) async {
    final set = await store.find(
      client,
      finder: Finder(filter: Filter.inList(idFieldKey, ids)),
    );
    return set.map((record) => fromJson(record.value)).toList(growable: false);
  }

  Future<T?> get(String id) async {
    final json = await store.record(id).get(client);
    return json == null ? null : fromJson(json);
  }

  Stream<List<T>> watchAll() {
    return store.query().onSnapshots(client).map(_valuesOf);
  }

  Future<void> put(T value) =>
      store.record(idOf(value)).put(client, toJson(value));

  Future<void> putAll(List<T> values) async {
    if (values.isEmpty) {
      return;
    }
    await client.transaction(
      (transaction) => store
          .records(values.map(idOf).toList(growable: false))
          .put(transaction, values.map(toJson).toList(growable: false)),
    );
  }

  Future<void> remove(String id) => store.record(id).delete(client);

  Future<void> removeWithIds(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await store.records(ids).delete(client);
  }

  List<T> _valuesOf(
    List<RecordSnapshot<String, Map<String, Object?>>> records,
  ) {
    return records
        .map((record) => fromJson(record.value))
        .toList(growable: false);
  }
}

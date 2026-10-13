class const DeletedEntity({
  required final String id,
  required final DateTime deletedAt,
});

typedef SyncChanges<T> = ({List<T> changed, List<DeletedEntity> deleted});

abstract class SyncApi<T> {
  Future<SyncChanges<T>> listChanges({
    required DateTime since,
    DateTime? until,
  });

  Future<bool> canBeReached();
}

abstract class SyncEntityDatabase<T> {
  Future<List<T>> getElementsWithIds(List<String> ids);
  Future<void> putAll(List<T> entities);
  Future<void> removeWithIds(List<String> ids);
}

abstract class SyncableModel {
  String get id;
  DateTime get lastChangedAt;
}

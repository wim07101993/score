import 'package:behaviour/behaviour.dart';
import 'package:logging/logging.dart';
import 'package:score/features/sync/storage/sync_dates_store.dart';

class Sync<T extends SyncableModel>({
  super.monitor,
  required final Logger logger,
  required final SyncEntityDatabase<T> db,
  required final SyncApi<T> api,
  required final SyncDatesStore syncDates,
  required final String syncDateKey,
  required final T Function(T existing, T updated) copyUpdate,
}) extends BehaviourWithoutInput<void> {
  static Future<void> _currentSync = Future.value();

  @override
  String get description => 'syncing the $syncDateKey';

  @override
  Future<void> action(BehaviourTrack? track) {
    return _currentSync = _currentSync.then((_) => sync());
  }

  Future<void> sync() async {
    final lastSync = await syncDates.lastSyncedAt(syncDateKey);
    final changedEntities = await api.listChanges(
      // avoid rounding errors on fetch timestamps
      since: lastSync.subtract(const Duration(seconds: 2)),
    );

    final existingEntities = await db.getElementsWithIds(
      changedEntities.map((entity) => entity.id).toList(growable: false),
    );

    final entitiesToSave = List<T>.empty(growable: true);
    for (final entity in changedEntities) {
      final existing = existingEntities
          .where((e) => e.id == entity.id)
          .firstOrNull;
      entitiesToSave.add(
        existing == null ? entity : copyUpdate(existing, entity),
      );
    }

    await db.putAll(entitiesToSave);

    // On the server's clock rather than this device's: a device whose clock
    // runs ahead would otherwise start the next window after changes the
    // server has yet to make.
    if (changedEntities.isEmpty) {
      return;
    }
    final newest = changedEntities
        .map((entity) => entity.lastChangedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    await syncDates.keepLastSyncedAt(syncDateKey, newest);
  }
}

abstract class SyncApi<T> {
  Future<List<T>> listChanges({
    required DateTime since,
    DateTime? until,
  });
}

abstract class SyncEntityDatabase<T> {
  Future<List<T>> getElementsWithIds(List<String> ids);
  Future<void> putAll(List<T> entities);
}

abstract class SyncableModel {
  String get id;
  DateTime get lastChangedAt;
}

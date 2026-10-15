import 'package:behaviour/behaviour.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/sync/models/syncable.dart';
import 'package:score/features/sync/storage/sync_dates_store.dart';

class Syncer<T extends SyncableModel>({
  super.monitor,
  required final Logger logger,
  required final SyncEntityDatabase<T> db,
  required final SyncApi<T> api,
  required final SyncDatesStore syncDates,
  required final String syncDateKey,
  required final T Function(T existing, T updated) copyUpdate,
  required final AuthNotifier authNotifier,
  required final ValueNotifier<bool> isSyncing,
}) extends BehaviourWithoutInput<void> {
  static final Map<String, Future<void>> _running = {};

  @override
  String get description => 'syncing the $syncDateKey';

  @override
  Future<void> action(BehaviourTrack? track) async {
    if (_running[syncDateKey] case final running?) {
      return running;
    }
    isSyncing.value = true;
    try {
      await (_running[syncDateKey] = sync());
    } finally {
      _running.remove(syncDateKey);
      isSyncing.value = false;
    }
  }

  Future<void> sync() async {
    if (authNotifier.value?.accessToken == null) {
      throw const NotAuthenticatedSyncerException();
    }
    if (!await api.canBeReached()) {
      throw const NoConnectionSyncerException();
    }

    final lastSync = await syncDates.lastSyncedAt(syncDateKey);
    final changes = await api.listChanges(
      // avoid rounding errors on fetch timestamps
      since: lastSync.subtract(const Duration(seconds: 2)),
    );
    final changedEntities = changes.changed;

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
    await db.removeWithIds(
      changes.deleted.map((entity) => entity.id).toList(growable: false),
    );

    // On the server's clock rather than this device's: a device whose clock
    // runs ahead would otherwise start the next window after changes the
    // server has yet to make.
    final moments = [
      ...changedEntities.map((entity) => entity.lastChangedAt),
      ...changes.deleted.map((entity) => entity.deletedAt),
    ];
    if (moments.isEmpty) {
      return;
    }
    final newest = moments.reduce((a, b) => a.isAfter(b) ? a : b);
    await syncDates.keepLastSyncedAt(syncDateKey, newest);
  }
}

sealed class const SyncerException() implements Exception {}

class const NotAuthenticatedSyncerException() extends SyncerException {}

class const NoConnectionSyncerException() extends SyncerException {}

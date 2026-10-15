import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/notifiers/is_syncing_collections_notifier.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/features/sync/behaviours/syncer.dart';

class SyncCollections({
  super.monitor,
  required super.logger,
  required super.syncDates,
  required super.authNotifier,
  required CollectionsDatabase db,
  required CollectionsApi api,
  required IsSyncingCollectionsNotifier isSyncing,
}) extends Syncer<Collection> {
  this
    : super(
        db: db,
        api: api,
        syncDateKey: key,
        copyUpdate: (existing, updated) => updated,
        isSyncing: isSyncing,
      );

  static const key = 'collections';
}

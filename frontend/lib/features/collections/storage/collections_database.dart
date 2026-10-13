import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/sync/models/syncable.dart';
import 'package:score/storage/record_store.dart';

class CollectionsDatabase({
  required super.client,
}) extends SembastStore<Collection> implements SyncEntityDatabase<Collection> {
  this
    : super(
        storeName: 'collections',
        fromJson: Collection.fromJson,
        toJson: (value) => value.toJson(),
        idOf: (value) => value.id,
        idFieldKey: Collection.idFieldKey,
      );
}

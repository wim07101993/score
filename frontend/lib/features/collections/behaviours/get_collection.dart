import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';

class GetCollection({
  super.monitor,
  required final CollectionsDatabase db,
  required final CollectionsApi api,
  required final FetchCollection fetch,
}) extends Behaviour<String, Collection?> {
  @override
  String get description => 'making sure a collection is on this device';

  @override
  Future<Collection?> action(String collectionId, BehaviourTrack? track) async {
    final existing = await db.get(collectionId);
    if (existing != null) {
      return existing.deletedAt == null ? existing : null;
    }
    if (!await api.canBeReached()) {
      return null;
    }
    return fetch.action(collectionId, track);
  }
}

class FetchCollection({
  super.monitor,
  required final CollectionsApi api,
  required final CollectionsDatabase db,
}) extends Behaviour<String, Collection?> {
  @override
  String get description => 'fetching a collection';

  @override
  Future<Collection?> action(String collectionId, BehaviourTrack? track) async {
    final collection = await api.getCollection(collectionId);
    if (collection == null) {
      await db.remove(collectionId);
      return null;
    }
    await db.put(collection);
    return collection.deletedAt == null ? collection : null;
  }
}

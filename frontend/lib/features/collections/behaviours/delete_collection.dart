import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';

class DeleteCollection({
  super.monitor,
  required final CollectionsApi api,
  required final CollectionsDatabase db,
}) extends Behaviour<String, void> {
  @override
  String get description => 'deleting a collection';

  @override
  Future<void> action(String collectionId, BehaviourTrack? track) async {
    track?.addAttribute('collection', collectionId);
    await api.deleteCollection(collectionId);
    await db.remove(collectionId);
  }
}

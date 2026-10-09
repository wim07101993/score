import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/sync/behaviours/update_collections.dart';

/// The collection with the given id, syncing the collections first when it is
/// not on this device: a link into one can be followed on a device that has
/// not synced since it was shared. Null when it is not there even then.
class EnsureCollection({
  super.monitor,
  required final CollectionsEngine engine,
  required final UpdateCollections updateCollections,
}) extends Behaviour<String, Collection?> {
  @override
  String get description => 'making sure a collection is on this device';

  @override
  Future<Collection?> action(String collectionId, BehaviourTrack? track) async {
    final known = engine.get(collectionId);
    if (known != null) {
      return known;
    }
    await updateCollections.action(track);
    return engine.get(collectionId);
  }
}

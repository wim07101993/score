import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';

/// Marks the collection as deleted here, and tells the server as soon as it
/// can.
///
/// It is kept rather than dropped, the same way the server keeps it: a sync
/// only asks about what changed since the last one, so a collection that was
/// simply forgotten here would be fetched straight back in as something new.
class DeleteCollection({
  super.monitor,
  required final CollectionsEngine engine,
}) extends Behaviour<String, void> {
  @override
  String get description => 'deleting a collection';

  @override
  Future<void> action(String collectionId, BehaviourTrack? track) {
    track?.addAttribute('collection', collectionId);
    return engine.delete(collectionId);
  }
}

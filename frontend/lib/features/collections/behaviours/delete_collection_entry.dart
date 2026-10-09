import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/models.dart';

class const DeleteCollectionEntryParams({
  required final String collectionId,
  required final String entryId,
});

/// Takes one piece out of a collection.
///
/// What every player said about how they look at it goes with it: it was
/// about a piece that is no longer in the collection.
class DeleteCollectionEntry({
  super.monitor,
  required final CollectionsEngine engine,
}) extends Behaviour<DeleteCollectionEntryParams, Collection> {
  @override
  String get description => 'taking a piece out of a collection';

  @override
  Future<Collection> action(
    DeleteCollectionEntryParams input,
    BehaviourTrack? track,
  ) {
    track?.addAttribute('collection', input.collectionId);
    return engine.deleteEntry(input.collectionId, input.entryId);
  }
}

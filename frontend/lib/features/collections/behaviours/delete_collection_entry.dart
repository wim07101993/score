import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/storage/collections_api.dart';

class const DeleteCollectionEntryParams({
  required final String collectionId,
  required final String entryId,
});

class DeleteCollectionEntry({
  super.monitor,
  required final CollectionsApi api,
  required final FetchCollection fetch,
}) extends Behaviour<DeleteCollectionEntryParams, Collection> {
  @override
  String get description => 'taking a piece out of a collection';

  @override
  Future<Collection> action(
    DeleteCollectionEntryParams input,
    BehaviourTrack? track,
  ) async {
    track?.addAttribute('collection', input.collectionId);
    await api.deleteEntry(input.collectionId, input.entryId);
    return await fetch.action(input.collectionId, track) ??
        (throw Exception(
          'failed to read back the collection which was just changed',
        ));
  }
}

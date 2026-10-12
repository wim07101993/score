import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/features/sets/models.dart';
import 'package:uuid/uuid.dart';

class const SaveCollectionParams({
  final String? id,
  required final String title,
  final String description = '',
  final List<String> sharedWith = const [],
});

class SaveCollection({
  super.monitor,
  required final CollectionsApi api,
  required final CollectionsDatabase db,
}) extends Behaviour<SaveCollectionParams, Collection> {
  static const _uuid = Uuid();

  @override
  String get description => 'saving a collection';

  @override
  Future<Collection> action(
    SaveCollectionParams input,
    BehaviourTrack? track,
  ) async {
    final collectionId = input.id ?? _uuid.v4();
    track?.addAttribute('collection', collectionId);
    final saved = await api.putCollection(collectionId, {
      'title': input.title,
      'description': input.description,
      'shared_with': addressesOf(input.sharedWith),
    });
    await db.put(saved);
    return saved;
  }
}

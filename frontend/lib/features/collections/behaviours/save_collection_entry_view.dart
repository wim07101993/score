import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/features/scores/models/score_view_settings.dart';

class const SaveCollectionEntryViewParams({
  required final String collectionId,
  required final String entryId,
  final int? transposition,
  final List<String>? hiddenParts,
  final double? zoom,
});

class SaveCollectionEntryView({
  super.monitor,
  required final CollectionsApi api,
  required final CollectionsDatabase db,
  required final FetchCollection fetch,
}) extends Behaviour<SaveCollectionEntryViewParams, Collection> {
  @override
  String get description => 'keeping how a piece of a collection is read';

  @override
  Future<Collection> action(
    SaveCollectionEntryViewParams input,
    BehaviourTrack? track,
  ) async {
    track?.addAttribute('collection', input.collectionId);
    final collection = await db.get(input.collectionId);
    final current =
        collection?.entries
            .where((entry) => entry.id == input.entryId)
            .firstOrNull
            ?.view ??
        const ScoreViewSettings.defaultView();

    final saved = await api.putEntryView(
      input.collectionId,
      input.entryId,
      ScoreViewSettings(
        transposition: input.transposition ?? current.transposition,
        hiddenParts: input.hiddenParts ?? current.hiddenParts,
        zoom: input.zoom ?? current.zoom,
      ).toJson(),
    );

    if (collection == null) {
      return await fetch.action(input.collectionId, track) ??
          (throw Exception(
            'failed to read back the collection which was just read',
          ));
    }
    final updated = collection.copyWith(
      entries: collection.entries
          .map(
            (entry) =>
                entry.id == input.entryId ? entry.copyWith(view: saved) : entry,
          )
          .toList(growable: false),
    );
    await db.put(updated);
    return updated;
  }
}

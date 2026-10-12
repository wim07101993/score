import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/models.dart';
import 'package:uuid/uuid.dart';

class const SaveCollectionEntryParams({
  required final String collectionId,
  final String? id,
  final String? scoreId,
  final bool onPaper = false,
  final String? description,
  final int? transposition,
});

class SaveCollectionEntry({
  super.monitor,
  required final CollectionsApi api,
  required final CollectionsDatabase db,
  required final FetchCollection fetch,
}) extends Behaviour<SaveCollectionEntryParams, Collection> {
  static const _uuid = Uuid();

  @override
  String get description => 'saving a piece of a collection';

  @override
  Future<Collection> action(
    SaveCollectionEntryParams input,
    BehaviourTrack? track,
  ) async {
    final collectionId = input.collectionId;
    track?.addAttribute('collection', collectionId);
    final entries =
        (await db.get(collectionId))?.entries ?? const <CollectionEntry>[];

    final entryId = input.id ?? _uuid.v4();
    final known = entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    final score = input.onPaper
        ? null
        : scoreIdOf(input.scoreId) ?? known?.scoreId;
    final written = input.description ?? known?.description ?? '';

    if (score != null && score != known?.scoreId) {
      final alreadyIn = entries
          .where(
            (candidate) =>
                candidate.id != entryId && candidate.scoreId == score,
          )
          .firstOrNull;
      if (alreadyIn != null) {
        throw ScoreAlreadyInCollectionException(
          scoreId: score,
          entryId: alreadyIn.id,
        );
      }
    }

    if (score == null && written.trim().isEmpty) {
      throw const UnnamedPieceException();
    }

    await api.putEntry(collectionId, entryId, {
      'score_id': score,
      'description': written,
      'transposition': (input.transposition ?? known?.transposition ?? 0).clamp(
        ScoreViewSettings.minTransposition,
        ScoreViewSettings.maxTransposition,
      ),
    });

    return await fetch.action(collectionId, track) ??
        (throw Exception(
          'failed to read back the collection which was just saved',
        ));
  }
}

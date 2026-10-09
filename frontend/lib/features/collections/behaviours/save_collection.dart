import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/models.dart';
import 'package:uuid/uuid.dart';

class const SaveCollectionParams({
  /// Null for a new collection.
  final String? id,
  required final String title,
  final String description = '',
  final List<String> sharedWith = const [],
});

/// Stores what a collection is — the group of pieces, and who may read it —
/// and hands it back.
///
/// What is in it is not touched: an entry is written on its own, so
/// correcting a title is correcting a title. A collection that is created
/// here is created empty and filled afterwards, the same way it is on the
/// server.
///
/// A collection that is only shared with this user is not this user's to
/// change, and writing one is refused rather than queued: there is no moment
/// later at which the server would take it.
class SaveCollection({
  super.monitor,
  required final CollectionsEngine engine,
}) extends Behaviour<SaveCollectionParams, Collection> {
  static const _uuid = Uuid();

  @override
  String get description => 'saving a collection';

  @override
  Future<Collection> action(
    SaveCollectionParams input,
    BehaviourTrack? track,
  ) {
    final collectionId = input.id ?? _uuid.v4();
    track?.addAttribute('collection', collectionId);
    return engine.save(
      collectionId,
      (existing) => Collection(
        id: collectionId,
        title: input.title,
        description: input.description,
        entries: existing?.entries ?? const [],
        sharedWith: addressesOf(input.sharedWith),
        isOwner: existing?.isOwner ?? true,
        lastChangedAt: DateTime.now(),
        // Nothing is carried over from a deletion, so writing a collection that
        // had been deleted brings it back: a client that still has it and edits
        // it is saying it should exist.
        lastSyncedAt: existing?.lastSyncedAt,
        pendingChange: PendingChange.write,
        pendingViews: existing?.pendingViews ?? const [],
        pendingEntries: existing?.pendingEntries ?? const [],
      ),
    );
  }
}

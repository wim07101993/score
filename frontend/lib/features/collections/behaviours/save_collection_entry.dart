import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/models.dart';
import 'package:uuid/uuid.dart';

class const SaveCollectionEntryParams({
  required final String collectionId,

  /// Null for a piece that is not in the collection yet.
  final String? id,

  /// Which piece it is. Left out keeps the score the entry has.
  final String? scoreId,

  /// Makes the entry a piece that is not in here: see [SaveCollectionEntry].
  final bool onPaper = false,
  final String? description,
  final int? transposition,
});

/// Puts one piece into a collection, or changes what the group does with it,
/// and hands the collection back as it now reads.
///
/// A collection holds a piece once. Adding a score the collection already
/// has is [ScoreAlreadyInCollectionException], which names the entry it is
/// already in — the caller wanted the piece to be in the book, and it is, so
/// what to do with that is the page's to decide rather than a write to make
/// twice. Writing the entry a score is already in is not that: it is saying
/// what the group does with a piece that is in the collection.
///
/// The pieces with no score are outside the rule: they are told apart by
/// what is written next to them, and two lines of a book nobody has scanned
/// are two pieces. Which is why one of those has to be called something — a
/// piece with no score and no name cannot be found, sorted, or told from the
/// next one, so it is refused here ([UnnamedPieceException]) rather than
/// queued for a server that will refuse it too.
///
/// Which piece it is, is only changed when the score is said at all: leaving
/// it out keeps the score the entry has, and saying it with `onPaper` makes
/// the entry a piece that is not in here. Null cannot mean both.
class SaveCollectionEntry({
  super.monitor,
  required final CollectionsEngine engine,
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
    await engine.takeInWhatOthersStored();
    final existing = engine.owned(collectionId);

    final entryId = input.id ?? _uuid.v4();
    final known = existing.entries
        .where((candidate) => candidate.id == entryId)
        .firstOrNull;
    final score = input.onPaper
        ? null
        : scoreIdOf(input.scoreId) ?? known?.scoreId;
    final written = input.description ?? known?.description ?? '';

    // Only a piece being put in, or an entry being changed to another score,
    // is asked about. An entry that keeps its score is a note or a key being
    // changed on a piece that is in here — and the collection can hold it twice
    // for a while, when two devices put it in offline, which is no reason to
    // refuse a note on either copy.
    if (score != null && score != known?.scoreId) {
      final alreadyIn = existing.entries
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

    final entry = CollectionEntry(
      id: entryId,
      scoreId: score,
      description: written,
      transposition: transpositionOf(
        input.transposition ?? known?.transposition,
      ),
      // How this user reads it is theirs and is written on its own, so an entry
      // that is renamed keeps it.
      view: known?.view ?? const CollectionEntryView(),
      synced: known?.synced ?? false,
    );

    // A piece that is already in the collection stays where it is in the list,
    // and a new one goes on the end. Neither says anything: a collection has no
    // order, and where a page draws a piece is where its title puts it.
    final entries = [
      for (final candidate in existing.entries)
        if (candidate.id == entryId) entry else candidate,
      if (known == null) entry,
    ];

    await engine.keep([
      engine.withEntries(
        existing,
        entries,
        owing(existing.pendingEntries, entryId, PendingChange.write),
      ),
    ]);
    await engine.pushIfPossible(collectionId);
    return engine.held(collectionId)!;
  }
}

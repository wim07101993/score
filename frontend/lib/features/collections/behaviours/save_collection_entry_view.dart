import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/models.dart';

class const SaveCollectionEntryViewParams({
  required final String collectionId,
  required final String entryId,
  final int? transposition,
  final List<String>? hiddenParts,
  final double? zoom,
});

/// Stores how this user looks at one entry, and tells the server as soon as
/// it can.
///
/// This is not writing the collection, and it is deliberately not asked to
/// be the owner of one: a view says nothing about the collection and changes
/// nothing anybody else sees, so a player who cannot add a piece to the book
/// can still say what key they read one in, which parts they want on screen,
/// and how big they draw it.
///
/// A view is written whole, so what is not said here is filled in from how
/// the entry is read now. Saying only that the key has changed is not saying
/// to draw the piece at the size every other one is drawn at, or to put the
/// parts that are off screen back on it.
class SaveCollectionEntryView({
  super.monitor,
  required final CollectionsEngine engine,
}) extends Behaviour<SaveCollectionEntryViewParams, Collection> {
  @override
  String get description => 'keeping how a piece of a collection is read';

  @override
  Future<Collection> action(
    SaveCollectionEntryViewParams input,
    BehaviourTrack? track,
  ) {
    track?.addAttribute('collection', input.collectionId);
    return engine.saveEntryView(
      input.collectionId,
      input.entryId,
      transposition: input.transposition,
      hiddenParts: input.hiddenParts,
      zoom: input.zoom,
    );
  }
}

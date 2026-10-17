import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';

/// Which collection this score is being played from, and which of its pieces
/// it is.
///
/// Where it comes in the collection is not kept: a collection has no order, so
/// the way through it is by title, and the titles are in the scores — which
/// can arrive after the page has opened. So it is worked out each time the bar
/// is drawn, and "3 of 21" means the third one down the page somebody was just
/// looking at.
class const CollectionContext({
  required final Collection collection,
  required final String entryId,
}) {
  CollectionEntry? get entry => collection.entries
      .where((candidate) => candidate.id == entryId)
      .firstOrNull;

  /// The same piece of the collection as it now stands, or of the collection
  /// as it was when there is no longer one on this device to read.
  CollectionContext refreshedFrom(Collection? now) {
    if (now == null || !now.entries.any((entry) => entry.id == entryId)) {
      return this;
    }
    return CollectionContext(collection: now, entryId: entryId);
  }
}

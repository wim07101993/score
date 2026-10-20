import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/models/collection_entry.dart';

/// Which collection this score is being played from, and which of its pieces
/// it is.
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

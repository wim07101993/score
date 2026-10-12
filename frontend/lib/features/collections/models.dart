/// A collection is a group of scores that belong together without being played
/// in any particular order: the pieces a book holds, the repertoire a band can
/// be asked for.
///
/// It is the other half of what a set is. A set is a gig, where the same song
/// may come round twice and the order is what is played; here order says
/// nothing, and a score is in it or it is not. Everything else is the same,
/// because it is the same music.
library;

/// The piece is already in the collection.
///
/// It is the one refusal that is worth acting on rather than reporting: what
/// the caller wanted was the piece to be in the book, and it is. What it is in
/// is [entryId], so a page can point at it instead of saying no.
class const ScoreAlreadyInCollectionException({
  required final String scoreId,

  /// The entry the score is already in.
  required final String entryId,
}) implements Exception {
  @override
  String toString() =>
      "Score '$scoreId' is already in this collection, as entry '$entryId'.";
}

/// A piece with no score has nothing to be called by but what is written next
/// to it, and one that says nothing cannot be found, sorted, or told from the
/// next one.
class const UnnamedPieceException() implements Exception {
  @override
  String toString() =>
      'A piece with no score has nothing to be called by but'
      ' what is written next to it.';
}

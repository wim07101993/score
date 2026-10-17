import 'package:auto_route/auto_route.dart';
import 'package:score/features/collections/models/collection_entry.dart';
import 'package:score/features/scores/widgets/score_detail/models/collection_context.dart';
import 'package:score/features/scores/widgets/score_detail/models/set_context.dart';
import 'package:score/router.dart';

/// The way through the set or the collection a score is played from: where
/// this one comes in it, and what comes either side.
class const WayThrough({
  required final bool isSet,

  /// What the set or the collection is called, and where it is.
  required final String title,
  required final PageRouteInfo route,

  /// Where this one comes in it, counted from one, and how many there are.
  required final int position,
  required final int count,

  /// Where the ones either side are, or null at either end.
  required final PageRouteInfo? previous,
  required final PageRouteInfo? next,

  /// What the set or the collection says next to this one.
  required final String note,
}) {
  /// The way through a set, in its running order.
  ///
  /// The next song either way, one played from paper included. That is not
  /// stepped over: it is what the band is playing, and a player looking at the
  /// song after it is lost when the band starts that one.
  factory WayThrough.ofSet({
    required SetContext context,
    required bool performing,
  }) {
    final set = context.set;
    PageRouteInfo? nearest(int step) {
      final index = context.index + step;
      if (index < 0 || index >= set.entries.length) return null;
      final entry = set.entries[index];
      final scoreId = entry.scoreId;
      return scoreId == null
          ? paperRoute(setId: set.id, entryId: entry.id)
          : scoreRoute(
              scoreId,
              setId: set.id,
              entryId: entry.id,
              performing: performing,
            );
    }

    return WayThrough(
      isSet: true,
      title: set.displayTitle,
      route: SetDetailRoute(setId: set.id),
      position: context.index + 1,
      count: set.entries.length,
      previous: nearest(-1),
      next: nearest(1),
      note: context.entry.description.trim(),
    );
  }

  /// The way through a collection, by title — one that has yet to be scanned
  /// included, as in a set. Null when the piece is no longer in it.
  static WayThrough? ofCollection(
    CollectionContext context, {
    required String? Function(String scoreId) titleOf,
    required bool performing,
  }) {
    final collection = context.collection;
    final entries = CollectionEntry.sortByTitle(collection.entries, titleOf);
    final index = entries.indexWhere((entry) => entry.id == context.entryId);
    if (index < 0) return null;

    PageRouteInfo? nearest(int step) {
      final at = index + step;
      if (at < 0 || at >= entries.length) return null;
      final candidate = entries[at];
      final scoreId = candidate.scoreId;
      return scoreId == null
          ? paperRoute(collectionId: collection.id, entryId: candidate.id)
          : scoreRoute(
              scoreId,
              collectionId: collection.id,
              entryId: candidate.id,
              performing: performing,
            );
    }

    return WayThrough(
      isSet: false,
      title: collection.displayTitle,
      route: CollectionDetailRoute(collectionId: collection.id),
      position: index + 1,
      count: entries.length,
      previous: nearest(-1),
      next: nearest(1),
      note: entries[index].description.trim(),
    );
  }
}

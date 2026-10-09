import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/models.dart';
import 'package:score/features/collections/storage/collections_store.dart';
import 'package:score/features/sync/behaviours/sync_engine.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
import 'package:score/notifiers/store_notifier.dart';

typedef StoredCollections = ({
  Map<String, Collection> collections,
  Map<String, WhyNotSynced> whyNotSynced,
});

/// The collections, as the store has them, and why what is owed about each of
/// them was not sent.
class CollectionsNotifier({
  required final CollectionsStore store,
  required final SyncHoldsStore holds,

  /// Where the edits that were given up on are heard: see [problems].
  required final CollectionsEngine engine,
}) extends StoreNotifier<StoredCollections> {
  this : super(initial: (collections: const {}, whyNotSynced: const {})) {
    follow(
      store.watchAll(),
      (records) => value = (
        collections: {
          for (final collection in records) collection.id: collection,
        },
        whyNotSynced: value.whyNotSynced,
      ),
    );
    follow(
      holds.watch(CollectionsAdapter.syncHoldKind),
      (holds) => value = (
        collections: value.collections,
        whyNotSynced: {
          for (final MapEntry(key: id, value: json) in holds.entries)
            id: WhyNotSynced.fromJson(json),
        },
      ),
    );
  }

  /// The collections there are, most recently changed first. The deleted ones
  /// are kept but are no longer collections anyone has.
  List<Collection> get collections => [
    for (final collection in value.collections.values)
      if (collection.deletedAt == null) collection,
  ]..sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));

  /// The collection with the given id, unless it is not here or has been
  /// deleted.
  Collection? getCollection(String collectionId) {
    final collection = value.collections[collectionId];
    return collection == null || collection.deletedAt != null
        ? null
        : collection;
  }

  /// The collections a score is in, most recently changed first.
  ///
  /// This is the question a collection exists to answer: a player who has a
  /// piece on screen wants to know which book it came out of and what else is
  /// in that book with it.
  List<Collection> collectionsWith(String scoreId) => [
    for (final collection in collections)
      if (collection.holds(scoreId)) collection,
  ];

  /// Whether anything here is still owed to the server.
  bool get hasPendingChanges =>
      value.collections.values.any((collection) => collection.owesAnything);

  /// Why what is owed about one collection was not sent the last time it was
  /// tried, or null when it has not been tried since the app started, or
  /// nothing is owed.
  WhyNotSynced? whyNotSynced(String collectionId) =>
      value.collections[collectionId]?.owesAnything == true
      ? value.whyNotSynced[collectionId]
      : null;

  /// The edits the server refused, as they are given up on.
  Stream<CollectionSyncProblem> get problems => engine.problems;
}

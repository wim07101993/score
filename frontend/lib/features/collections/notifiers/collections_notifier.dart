import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/notifiers/store_notifier.dart';

class CollectionsNotifier({
  required final CollectionsDatabase store,
}) extends StreamNotifier<Map<String, Collection>> {
  this : super(initial: const {}) {
    follow(
      store.watchAll().map(
        (records) => {
          for (final collection in records) collection.id: collection,
        },
      ),
    );
  }

  List<Collection> get collections => [
    for (final collection in value.values)
      if (collection.deletedAt == null) collection,
  ]..sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));

  Collection? getCollection(String collectionId) {
    final collection = value[collectionId];
    return collection == null || collection.deletedAt != null
        ? null
        : collection;
  }

  List<Collection> collectionsWith(String scoreId) => [
    for (final collection in collections)
      if (collection.holds(scoreId)) collection,
  ];
}

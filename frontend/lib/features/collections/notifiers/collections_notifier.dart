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

  List<Collection> get collections =>
      [...value.values]
        ..sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));

  Collection? getCollection(String collectionId) => value[collectionId];
}

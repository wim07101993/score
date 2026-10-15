import 'package:score/features/collections/models/collection.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/notifiers/store_notifier.dart';

class CollectionsNotifier({
  required final CollectionsDatabase store,
}) extends StreamNotifier<List<Collection>> {
  this : super(initial: const []) {
    follow(store.watchAll());
  }

  List<Collection> get collections =>
      value..sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));

  Collection? getCollection(String collectionId) {
    return value
        .where((collection) => collection.id == collectionId)
        .firstOrNull;
  }
}

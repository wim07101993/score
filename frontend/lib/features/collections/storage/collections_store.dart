import 'package:score/features/collections/models.dart';
import 'package:score/storage/record_store.dart';

/// The collections this device keeps, what is still owed about them included.
class CollectionsStore({
  required super.client,
}) extends SembastStore<Collection> {
  this
    : super(
        storeName: 'collections',
        fromJson: Collection.fromJson,
        toJson: (value) => value.toJson(),
        idOf: (value) => value.id,
      );
}

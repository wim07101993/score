import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/notifiers/store_notifier.dart';

class SetsNotifier({
  required final SetsDatabase store,
}) extends StreamNotifier<Map<String, ScoreSet>> {
  this : super(initial: const {}) {
    follow(
      store.watchAll().map(
        (records) => {for (final set in records) set.id: set},
      ),
    );
  }

  List<ScoreSet> get sets => [
    for (final set in value.values)
      if (set.deletedAt == null) set,
  ]..sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));

  ScoreSet? getSet(String setId) {
    final set = value[setId];
    return set == null || set.deletedAt != null ? null : set;
  }
}

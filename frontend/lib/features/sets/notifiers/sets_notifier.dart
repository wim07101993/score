import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/notifiers/store_notifier.dart';

class SetsNotifier({
  required final SetsDatabase store,
}) extends StreamNotifier<List<ScoreSet>> {
  this : super(initial: []) {
    follow(store.watchAll());
  }

  List<ScoreSet> get sets =>
      value..sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));

  ScoreSet? getSet(String setId) {
    return value.where((set) => set.id == setId).firstOrNull;
  }
}

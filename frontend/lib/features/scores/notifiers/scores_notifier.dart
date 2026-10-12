import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:score/notifiers/store_notifier.dart';

class ScoresNotifier({
  required final ScoresDatabase store,
}) extends StreamNotifier<Map<String, Score>> {
  this : super(initial: const {}) {
    follow(
      store.watchAll().map(
        (records) => {for (final score in records) score.id: score},
      ),
    );
  }

  List<Score>? _sorted;

  @override
  set value(Map<String, Score> scores) {
    _sorted = null;
    super.value = scores;
  }

  List<Score> get scores {
    final cached = _sorted;
    if (cached != null) {
      return cached;
    }
    final all = value.values.toList();
    all.sort((a, b) {
      final byViewed = (b.lastViewedAt ?? DateTime.utc(1970)).compareTo(
        a.lastViewedAt ?? DateTime.utc(1970),
      );
      return byViewed != 0 ? byViewed : a.title.compareTo(b.title);
    });
    return _sorted = List.unmodifiable(all);
  }

  Score? getScore(String scoreId) => value[scoreId];
}

import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_store.dart';
import 'package:score/features/sync/behaviours/sync_engine.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
import 'package:score/notifiers/store_notifier.dart';

typedef StoredSets = ({
  Map<String, ScoreSet> sets,
  Map<String, WhyNotSynced> whyNotSynced,
});

/// The sets, as the store has them, and why what is owed about each of them
/// was not sent.
class SetsNotifier({
  required final SetsStore store,
  required final SyncHoldsStore holds,

  /// Where the edits that were given up on are heard: see [problems].
  required final SetsEngine engine,
}) extends StreamNotifier<StoredSets> {
  this : super(initial: (sets: const {}, whyNotSynced: const {})) {
    follow(
      store.watchAll().map(
        (records) => (
          sets: {for (final set in records) set.id: set},
          whyNotSynced: value.whyNotSynced,
        ),
      ),
    );
    follow(
      holds
          .watch(SetsAdapter.syncHoldKind)
          .map(
            (holds) => (
              sets: value.sets,
              whyNotSynced: {
                for (final MapEntry(key: id, value: json) in holds.entries)
                  id: WhyNotSynced.fromJson(json),
              },
            ),
          ),
    );
  }

  /// The sets there are, most recently changed first. The deleted ones are kept
  /// but are no longer sets anyone has.
  List<ScoreSet> get sets => [
    for (final set in value.sets.values)
      if (set.deletedAt == null) set,
  ]..sort((a, b) => b.lastChangedAt.compareTo(a.lastChangedAt));

  /// The set with the given id, unless it is not here or has been deleted.
  ScoreSet? getSet(String setId) {
    final set = value.sets[setId];
    return set == null || set.deletedAt != null ? null : set;
  }

  /// Whether anything here is still owed to the server.
  bool get hasPendingChanges =>
      value.sets.values.any((set) => set.owesAnything);

  /// Why what is owed about one set was not sent the last time it was tried,
  /// or null when it has not been tried since the app started, or nothing is
  /// owed.
  WhyNotSynced? whyNotSynced(String setId) =>
      value.sets[setId]?.owesAnything == true
      ? value.whyNotSynced[setId]
      : null;

  /// The edits the server refused, as they are given up on.
  Stream<SyncProblem> get problems => engine.problems;
}

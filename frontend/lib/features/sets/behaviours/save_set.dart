import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/models.dart';
import 'package:uuid/uuid.dart';

class const SaveSetParams({
  /// Null for a new set.
  final String? id,
  required final String title,
  final String description = '',
  final List<String> sharedWith = const [],
});

/// Stores what a set is — the gig, and who may read it — and hands it back.
///
/// What is played in it is not touched: an entry is written on its own, so
/// correcting a title is correcting a title.
///
/// A set that is only shared with this user is not this user's to change, and
/// writing one is refused rather than queued: there is no moment later at
/// which the server would take it.
class SaveSet({
  super.monitor,
  required final SetsEngine engine,
}) extends Behaviour<SaveSetParams, ScoreSet> {
  static const _uuid = Uuid();

  @override
  String get description => 'saving a set';

  @override
  Future<ScoreSet> action(SaveSetParams input, BehaviourTrack? track) {
    final setId = input.id ?? _uuid.v4();
    track?.addAttribute('set', setId);
    return engine.save(
      setId,
      (existing) => ScoreSet(
        id: setId,
        title: input.title,
        description: input.description,
        entries: existing?.entries ?? const [],
        sharedWith: addressesOf(input.sharedWith),
        isOwner: existing?.isOwner ?? true,
        lastChangedAt: DateTime.now(),
        // Nothing is carried over from a deletion, so writing a set that had
        // been deleted brings it back: a client that still has it and edits it
        // is saying it should exist.
        lastSyncedAt: existing?.lastSyncedAt,
        pendingChange: PendingChange.write,
        pendingViews: existing?.pendingViews ?? const [],
        pendingEntries: existing?.pendingEntries ?? const [],
      ),
    );
  }
}

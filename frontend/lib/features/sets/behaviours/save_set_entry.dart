import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/models.dart';
import 'package:uuid/uuid.dart';

class const SaveSetEntryParams({
  required final String setId,

  /// Null for a song that is not in the set yet.
  final String? id,
  final String? scoreId,
  final String? description,
  final int? transposition,

  /// Where in the running order; null leaves it where it is.
  final int? position,
});

/// Puts one score into a set, or changes how it is played, and hands the set
/// back as it now reads.
///
/// The set is closed up around it: an entry written at a place the set
/// already has an entry in puts that one and everything after it back by one,
/// and an entry that is already in the set and is written at another place
/// moves there. A place beyond the end of the set is the end of the set. No
/// place at all leaves an entry that is already in the set where it is — a
/// note or a key is written without one — and puts a new one at the end.
class SaveSetEntry({
  super.monitor,
  required final SetsEngine engine,
}) extends Behaviour<SaveSetEntryParams, ScoreSet> {
  static const _uuid = Uuid();

  @override
  String get description => 'saving a song of a set';

  @override
  Future<ScoreSet> action(
    SaveSetEntryParams input,
    BehaviourTrack? track,
  ) async {
    final setId = input.setId;
    track?.addAttribute('set', setId);
    await engine.takeInWhatOthersStored();
    final existing = engine.owned(setId);

    final entryId = input.id ?? _uuid.v4();
    final known = existing.entries
        .where((entry) => entry.id == entryId)
        .firstOrNull;

    final written = SetEntry(
      id: entryId,
      scoreId: scoreIdOf(input.scoreId) ?? known?.scoreId,
      description: input.description ?? known?.description ?? '',
      transposition: transpositionOf(
        input.transposition ?? known?.transposition,
      ),
      // How this user reads it is theirs and is written on its own, so an entry
      // that is moved or renamed keeps it.
      view: known?.view ?? const EntryView(),
      synced: known?.synced ?? false,
    );

    final others = existing.entries
        .where((entry) => entry.id != entryId)
        .toList();
    // Where it already is, unless it is being moved: taking "no place" for the
    // end would send a song to the back of the gig — for everyone it is shared
    // with — because somebody corrected its note.
    final here = existing.entries.indexWhere((entry) => entry.id == entryId);
    final at = (input.position ?? (here < 0 ? others.length : here)).clamp(
      0,
      others.length,
    );

    await engine.keep([
      engine.withEntries(
        existing,
        [...others.sublist(0, at), written, ...others.sublist(at)],
        owing(existing.pendingEntries, entryId, PendingChange.write),
      ),
    ]);
    await engine.pushIfPossible(setId);
    return engine.held(setId)!;
  }
}

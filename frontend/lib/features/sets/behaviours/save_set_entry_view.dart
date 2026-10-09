import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/models.dart';

class const SaveSetEntryViewParams({
  required final String setId,
  required final String entryId,
  final int? transposition,
  final List<String>? hiddenParts,
  final double? zoom,
});

/// Stores how this user looks at one entry, and tells the server as soon as
/// it can.
///
/// This is not writing the set, and it is deliberately not asked to be the
/// owner of one: a view says nothing about the set and changes nothing
/// anybody else sees, so a player who cannot change a note of the running
/// order can still say what key they read it in and which parts they want on
/// screen.
class SaveSetEntryView({
  super.monitor,
  required final SetsEngine engine,
}) extends Behaviour<SaveSetEntryViewParams, ScoreSet> {
  @override
  String get description => 'keeping how a song of a set is read';

  @override
  Future<ScoreSet> action(
    SaveSetEntryViewParams input,
    BehaviourTrack? track,
  ) {
    track?.addAttribute('set', input.setId);
    return engine.saveEntryView(
      input.setId,
      input.entryId,
      transposition: input.transposition,
      hiddenParts: input.hiddenParts,
      zoom: input.zoom,
    );
  }
}

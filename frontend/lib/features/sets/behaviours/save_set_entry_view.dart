import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/behaviours/get_set.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';

class const SaveSetEntryViewParams({
  required final String setId,
  required final String entryId,
  final int? transposition,
  final List<String>? hiddenParts,
  final double? zoom,
});

class SaveSetEntryView({
  super.monitor,
  required final SetsApi api,
  required final SetsDatabase db,
  required final FetchSet fetch,
}) extends Behaviour<SaveSetEntryViewParams, ScoreSet> {
  @override
  String get description => 'keeping how a song of a set is read';

  @override
  Future<ScoreSet> action(
    SaveSetEntryViewParams input,
    BehaviourTrack? track,
  ) async {
    track?.addAttribute('set', input.setId);
    final set = await db.get(input.setId);
    final current =
        set?.entries
            .where((entry) => entry.id == input.entryId)
            .firstOrNull
            ?.view ??
        const ScoreViewSettings.defaultView();

    final saved = await api.putEntryView(
      input.setId,
      input.entryId,
      ScoreViewSettings(
        transposition: input.transposition ?? current.transposition,
        hiddenParts: input.hiddenParts ?? current.hiddenParts,
        zoom: input.zoom ?? current.zoom,
      ).toJson(),
    );

    if (set == null) {
      return await fetch.action(input.setId, track) ??
          (throw Exception('failed to read back the set which was just read'));
    }
    final updated = set.copyWith(
      entries: set.entries
          .map(
            (entry) =>
                entry.id == input.entryId ? entry.copyWith(view: saved) : entry,
          )
          .toList(growable: false),
    );
    await db.put(updated);
    return updated;
  }
}

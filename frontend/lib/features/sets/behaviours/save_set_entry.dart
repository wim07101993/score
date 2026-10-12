import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/sets/behaviours/get_set.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:uuid/uuid.dart';

class const SaveSetEntryParams({
  required final String setId,
  final String? id,
  final String? scoreId,
  final String? description,
  final int? transposition,
  final int? position,
});

class SaveSetEntry({
  super.monitor,
  required final SetsApi api,
  required final SetsDatabase db,
  required final FetchSet fetch,
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
    final entries = (await db.get(setId))?.entries ?? const <SetEntry>[];

    final entryId = input.id ?? _uuid.v4();
    final known = entries.where((entry) => entry.id == entryId).firstOrNull;
    final others = entries.where((entry) => entry.id != entryId).length;
    final here = entries.indexWhere((entry) => entry.id == entryId);
    final position = (input.position ?? (here < 0 ? others : here)).clamp(
      0,
      others,
    );

    await api.putEntry(setId, entryId, {
      'score_id': scoreIdOf(input.scoreId) ?? known?.scoreId,
      'description': input.description ?? known?.description ?? '',
      'transposition': (input.transposition ?? known?.transposition ?? 0).clamp(
        ScoreViewSettings.minTransposition,
        ScoreViewSettings.maxTransposition,
      ),
      'position': position,
    });

    return await fetch.action(setId, track) ??
        (throw Exception('failed to read back the set which was just saved'));
  }
}

import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:uuid/uuid.dart';

class const SaveSetParams({
  final String? id,
  required final String title,
  final String description = '',
  final List<String> sharedWith = const [],
});

class SaveSet({
  super.monitor,
  required final SetsApi api,
  required final SetsDatabase db,
}) extends Behaviour<SaveSetParams, ScoreSet> {
  static const _uuid = Uuid();

  @override
  String get description => 'saving a set';

  @override
  Future<ScoreSet> action(SaveSetParams input, BehaviourTrack? track) async {
    final setId = input.id ?? _uuid.v4();
    track?.addAttribute('set', setId);
    final saved = await api.putSet(setId, {
      'title': input.title,
      'description': input.description,
      'shared_with': addressesOf(input.sharedWith),
    });
    await db.put(saved);
    return saved;
  }
}

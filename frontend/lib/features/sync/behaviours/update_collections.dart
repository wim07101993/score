import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/sync_collections.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/sync/behaviours/api_sync.dart';
import 'package:score/features/sync/behaviours/one_at_a_time.dart';

class UpdateCollections({
  super.monitor,
  required final CollectionsApi api,
  required final SyncCollections syncCollections,
  required final ApiSync apiSync,
  required final OneAtATime oneAtATime,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'updating the collections';

  @override
  Future<void> action(BehaviourTrack? track) => oneAtATime(
    'collections',
    () => apiSync(
      what: 'syncing the collections',
      apiCanBeReached: api.canBeReached,
      sync: () => syncCollections.action(track),
    ),
  );
}

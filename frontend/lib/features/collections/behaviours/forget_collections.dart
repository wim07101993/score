import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';

/// Forgets every collection on this device, what is owed about them included,
/// for a device that is handed to somebody else.
class ForgetCollections({
  super.monitor,
  required final CollectionsEngine engine,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'forgetting the collections on this device';

  @override
  Future<void> action(BehaviourTrack? track) => engine.forgetAll();
}

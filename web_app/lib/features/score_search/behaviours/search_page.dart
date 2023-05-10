import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:behaviour/behaviour.dart';

class SearchPage extends Behaviour<int, void> {
  SearchPage({
    required super.monitor,
    required this.hitsSearcher,
  });

  final HitsSearcher hitsSearcher;

  @override
  Future<void> action(int input, BehaviourTrack? track) {
    hitsSearcher.applyState((state) => state.copyWith(page: input));
    return Future.value();
  }
}

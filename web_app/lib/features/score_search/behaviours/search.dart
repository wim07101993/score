import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:behaviour/behaviour.dart';

class Search extends Behaviour<String, void> {
  Search({
    required super.monitor,
    required this.hitsSearcher,
  });

  final HitsSearcher hitsSearcher;

  @override
  Future<void> action(String input, BehaviourTrack? track) {
    hitsSearcher.applyState((state) => state.copyWith(query: input, page: 0));
    return Future.value();
  }
}

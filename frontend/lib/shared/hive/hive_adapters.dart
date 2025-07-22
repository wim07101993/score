import 'package:hive_ce/hive.dart';
import 'package:score/features/scores/score.dart';

@GenerateAdapters([
  AdapterSpec<Score>(),
  AdapterSpec<Movement>(),
  AdapterSpec<Work>(),
  AdapterSpec<Creators>(),
])
part 'hive_adapters.g.dart';

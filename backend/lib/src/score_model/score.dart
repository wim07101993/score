import 'package:score_backend/src/score_model/creator.dart';
import 'package:score_backend/src/score_model/part_list.dart';

export 'creator.dart';
export 'part_list.dart';

class Score {
  const Score({
    required this.title,
    required this.creators,
    required this.partList,
    required this.parts,
  });

  final String title;
  final List<Creator> creators;
  final List<PartListItem> partList;
  final List<ScorePart> parts;
}

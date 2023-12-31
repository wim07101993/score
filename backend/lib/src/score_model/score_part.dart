import 'package:score_backend/src/score_model/clef.dart';
import 'package:score_backend/src/score_model/direction.dart';
import 'package:score_backend/src/score_model/key.dart';
import 'package:score_backend/src/score_model/time.dart';

export 'package:score_backend/src/score_model/clef.dart';
export 'package:score_backend/src/score_model/direction.dart';
export 'package:score_backend/src/score_model/key.dart';
export 'package:score_backend/src/score_model/time.dart';

class ScorePart {
  const ScorePart({
    required this.divisions,
    required this.key,
    required this.time,
    required this.staves,
    required this.clefs,
    required this.direction,
  });

  final int divisions;
  final Key key;
  final Time time;
  final int staves;
  final List<Clef> clefs;
  final Direction direction;
  // TODO
}

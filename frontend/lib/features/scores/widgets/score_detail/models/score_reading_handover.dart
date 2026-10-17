import 'package:score/features/notation/view/score_view.dart';

class const ScoreReadingHandover({
  required final ScoreView view,
  required final double zoom,
  required final void Function(ScoreView view, double zoom) onReturn,
});

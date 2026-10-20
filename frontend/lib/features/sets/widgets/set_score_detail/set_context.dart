import 'package:score/features/sets/models.dart';

/// Which set this score is being played from, and where in it.
class const SetContext({
  required final ScoreSet set,
  required final int index,
}) {
  SetEntry get entry => set.entries[index];
}

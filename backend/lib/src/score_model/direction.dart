import 'package:score_backend/src/score_model/positioning.dart';

export 'package:score_backend/src/score_model/positioning.dart';

sealed class Direction {
  const Direction({
    required this.offset,
    required this.staff,
  });

  final Offset offset;
  final int staff;
}

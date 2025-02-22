import 'package:cbl/cbl.dart';

export 'score.cbl.database.g.dart';

part 'score.cbl.type.g.dart';

@TypedDatabase(types: {Score, Work, Movement, Creators})
abstract class $ScoresDatabase {}

@TypedDocument()
abstract class Score with _$Score {
  factory Score({
    @DocumentId() required String id,
    required Work? work,
    required Movement? movement,
    required Creators creators,
    required List<String> instruments,
    required List<String> languages,
    required List<String> tags,
    required DateTime lastChangeTimestamp,
    required bool isFavourite,
  }) = MutableScore;

  static const String lastChangeTimestampPropertyName = 'lastChangeTimestamp';
}

@TypedDocument()
abstract class Work with _$Work {
  factory Work({
    required String title,
    required String number,
  }) = MutableWork;
}

@TypedDocument()
abstract class Movement with _$Movement {
  factory Movement({
    required String title,
    required String number,
  }) = MutableMovement;
}

@TypedDocument()
abstract class Creators with _$Creators {
  factory Creators({
    required List<String> composers,
    required List<String> lyricists,
  }) = MutableCreators;
}

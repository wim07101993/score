import 'package:cbl/cbl.dart';

part 'score.cbl.type.g.dart';

@TypedDatabase(types: {Score})
abstract class $ScoresDatabase {}

@TypedDocument()
abstract class Score with _$Score {
  factory Score({
    @DocumentId() required String id,
    required String title,
    required List<String> composers,
    required List<String> lyricists,
    required List<String> instruments,
    required bool isFavourite,
    required DateTime lastChangeTimestamp,
  }) = MutableScore;

  static const String lastChangeTimestampPropertyName = 'lastChangeTimestamp';
}

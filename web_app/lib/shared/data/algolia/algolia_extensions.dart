import 'package:algolia/algolia.dart';
import 'package:score/shared/data/algolia/algolia_model_field_names.dart';
import 'package:score/shared/data/map_helpers.dart';
import 'package:score/shared/models/pagination_page.dart';
import 'package:score/shared/models/score.dart';

extension AlgoliaExtensions on Algolia {
  AlgoliaIndexReference get scoresIndex => index('scores');

  Future<PaginationPage<Score>> searchScores({
    required String searchString,
    required int pageIndex,
    required int pageSize,
  }) async {
    return index('scores')
        .query(searchString)
        .setHitsPerPage(pageSize)
        .setPage(pageIndex)
        .getObjects()
        .then((value) {
      return PaginationPage(
        index: value.page,
        size: value.length,
        numberOfPages: value.nbPages,
        items: value.hits.map(_convertToScore).whereType<Score>().toList(),
      );
    });
  }

  Score? _convertToScore(AlgoliaObjectSnapshot objectSnapshot) {
    final data = objectSnapshot.data;
    final id = data[ScoreFields.id] as String?;
    final title = data[ScoreFields.title] as String?;
    final subtitle = data[ScoreFields.subtitle] as String?;
    final dedication = data[ScoreFields.dedication] as String?;
    final composers = data.getList<String>(ScoreFields.composers);
    final createdAt = data.getDateTime(ScoreFields.createdAt);
    final modifiedAt = data.getDateTime(ScoreFields.modifiedAt);
    if (id == null ||
        title == null ||
        composers == null ||
        createdAt == null ||
        modifiedAt == null) {
      return null;
    }
    return Score(
      id: id,
      title: title,
      subtitle: subtitle,
      dedication: dedication,
      composers: composers,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }
}

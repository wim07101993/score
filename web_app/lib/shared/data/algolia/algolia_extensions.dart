import 'package:algolia/algolia.dart';
import 'package:score/shared/data/algolia/algolia_model_field_names.dart';
import 'package:score/shared/data/map_helpers.dart';
import 'package:score/shared/models/arrangement.dart';
import 'package:score/shared/models/arrangement_part.dart';
import 'package:score/shared/models/instrument.dart';
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
        items: value.hits.map(_snapshotToScore).whereType<Score>().toList(),
      );
    });
  }

  Score? _snapshotToScore(AlgoliaObjectSnapshot objectSnapshot) {
    final data = objectSnapshot.data;
    final id = data.maybeGet<String>(ScoreFields.id);
    final title = data.maybeGet<String>(ScoreFields.title);
    final subtitle = data.maybeGet<String>(ScoreFields.subtitle);
    final dedication = data.maybeGet<String>(ScoreFields.dedication);
    final composers = data
        .maybeGetList<String>(ScoreFields.composers)
        ?.toList(growable: false);
    final createdAt = data.maybeGetDateTime(ScoreFields.createdAt);
    final modifiedAt = data.maybeGetDateTime(ScoreFields.modifiedAt);
    final arrangements = data
        .maybeGetListConverted<Arrangement>(
          ScoreFields.arrangements,
          _mapToArrangement,
        )
        ?.toList(growable: false);
    final tags =
        data.maybeGetList<String>(ScoreFields.tags)?.toList(growable: false);

    if (id == null ||
        title == null ||
        createdAt == null ||
        modifiedAt == null) {
      return null;
    }
    return SavedScore(
      id: id,
      title: title,
      subtitle: subtitle,
      dedication: dedication,
      composers: composers ?? const [],
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      arrangements: arrangements ?? const [],
      tags: tags ?? const [],
    );
  }

  Arrangement? _mapToArrangement(Map<String, dynamic> json) {
    final name = json.maybeGet<String>(ArrangementFields.name);
    if (name == null) {
      return null;
    }
    return SavedArrangement(
      name: name,
      arrangers: json
              .maybeGetList<String>(ArrangementFields.arrangers)
              ?.toList(growable: false) ??
          const [],
      parts: json
              .maybeGetList<Map<String, dynamic>>(ArrangementFields.parts)
              ?.map(_mapToArrangementPart)
              .whereType<ArrangementPart>()
              .toList(growable: false) ??
          const [],
      lyricists: json
              .maybeGetList<String>(ArrangementFields.lyricists)
              ?.toList(growable: false) ??
          const [],
      description: json.maybeGet<String>(ArrangementFields.description),
    );
  }

  ArrangementPart? _mapToArrangementPart(Map<String, dynamic> json) {
    return SavedArrangementPart(
      links: json
              .maybeGetList<String>(ArrangementPartFields.links)
              ?.map(Uri.parse)
              .toList(growable: false) ??
          const [],
      instruments: json
              .maybeGetList<String>(ArrangementPartFields.targetInstrument)
              ?.map(Instrument.parse)
              .toList(growable: false) ??
          const [],
      description: json.maybeGet(ArrangementPartFields.description),
    );
  }
}

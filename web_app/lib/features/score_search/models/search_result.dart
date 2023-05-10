import 'dart:async';
import 'dart:convert';

import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:score/features/score_search/models/part.dart';
import 'package:score/features/score_search/models/score.dart';
import 'package:score/shared/dependency_management/global_value.dart';
import 'package:score/shared/json_extensions.dart';

class SearchResult {
  SearchResult({
    required this.hits,
    required this.numberOfHits,
    required this.pageKey,
    required this.numberOfPages,
  });

  final List<Score> hits;
  final int numberOfHits;
  final int pageKey;
  final int numberOfPages;

  bool get isFirstPage => pageKey == 0;
  bool get isLastPage => pageKey < numberOfPages;
  int? get nextPage => isLastPage ? null : pageKey + 1;
}

class SearchResultValue implements ReadOnlyGlobalValue<SearchResult?> {
  SearchResultValue({
    required this.searcher,
    required Converter<Hit, Score> hitConverter,
    required Logger logger,
  }) {
    _searcherResponseSubscription = searcher.responses.listen((response) {
      logger.i('received response ${response.page}');
      _value = SearchResult(
        hits: response.hits.map(hitConverter.convert).toList(growable: false),
        numberOfHits: response.nbHits,
        pageKey: response.page,
        numberOfPages: response.nbPages,
      );
    });
  }

  final HitsSearcher searcher;
  final StreamController<SearchResult?> _streamController =
      StreamController.broadcast();
  late final StreamSubscription _searcherResponseSubscription;

  SearchResult? _value;

  @override
  Stream<SearchResult?> get changes => _streamController.stream;

  @override
  SearchResult? get value => _value;

  Future<void> dispose() => _searcherResponseSubscription.cancel();

  @override
  Future<ReadOnlyGlobalValue<SearchResult?>> initialize() => Future.value(this);
}

class HitConverter extends Converter<Hit, Score> {
  const HitConverter();

  @override
  Score convert(Hit input) {
    return Score(
      title: input.get<String>('title'),
      arrangementName: input.maybeGet('arrangementName'),
      alsoKnownAs: input.getList('alsoKnownAs'),
      composers: input.getList('composers'),
      lyricists: input.getList('lyricists'),
      parts: input.getObjectList(
        'parts',
        (part) => Part(
          name: part.get('name'),
          instruments: part.getList('instruments'),
          files: part.getObjectList(
            'files',
            (file) => LinkedFile(link: file.get('link')),
          ),
        ),
      ),
    );
  }
}

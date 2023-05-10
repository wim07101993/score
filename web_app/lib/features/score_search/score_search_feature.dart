import 'dart:convert';

import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/score_search/behaviours/search.dart';
import 'package:score/features/score_search/behaviours/search_page.dart';
import 'package:score/features/score_search/models/score.dart';
import 'package:score/features/score_search/models/search_result.dart';
import 'package:score/shared/algolia/algolia_options.dart';
import 'package:score/shared/dependency_management/feature.dart';
import 'package:score/shared/dependency_management/get_it_extensions.dart';

class ScoreSearchFeature extends Feature {
  const ScoreSearchFeature();

  @override
  void registerTypes(GetIt getIt) {
    getIt.registerLazySingleton<HitsSearcher>(
      () => HitsSearcher(
        applicationID: 'HL4S0JBW73',
        apiKey: DefaultAlgoliaOptions.algoliaApiKey,
        indexName: 'scores',
      ),
      dispose: (instance) => instance.dispose(),
    );

    getIt.registerLazySingleton<Converter<Hit, Score>>(
      () => const HitConverter(),
    );
    getIt.registerLazySingleton(
      () => SearchResultValue(
        searcher: getIt(),
        hitConverter: getIt(),
        logger: getIt.logger<SearchResultValue>(),
      ),
    );

    getIt.registerFactory(
      () => Search(monitor: getIt(), hitsSearcher: getIt()),
    );
    getIt.registerFactory(
      () => SearchPage(monitor: getIt(), hitsSearcher: getIt()),
    );
  }
}

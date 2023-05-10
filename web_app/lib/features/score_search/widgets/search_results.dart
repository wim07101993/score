import 'dart:async';

import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:score/features/logging/logging_widget_extensions.dart';
import 'package:score/features/score_search/models/score.dart';
import 'package:score/features/score_search/models/search_result.dart';
import 'package:score/features/score_search/widgets/score_list_item.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';

class SearchResults extends StatefulWidget {
  const SearchResults({super.key});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  final _pagingController = PagingController<int, Score>(firstPageKey: 0);
  late final HitsSearcher _searcher = context.getIt();
  late final StreamSubscription _searchResultSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _searchResultSubscription = context
        .getIt<SearchResultValue>()
        .changes
        .where((result) => result != null)
        .cast<SearchResult>()
        .listen(appendPage);

    _pagingController.addPageRequestListener(requestPage);
  }

  void appendPage(SearchResult result) {
    logger.i('received page ${result.pageKey}');
    if (result.isFirstPage) {
      _pagingController.refresh();
    }
    _pagingController.appendPage(result.hits, result.nextPage);
  }

  void requestPage(int pageKey) {
    logger.i('requesting page $pageKey');
    _searcher.applyState((state) => state.copyWith(page: pageKey));
  }

  @override
  void dispose() {
    _searchResultSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, Score>(
      pagingController: _pagingController,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      builderDelegate: PagedChildBuilderDelegate(
        itemBuilder: (context, score, index) => ScoreListItem(score: score),
      ),
    );
  }
}

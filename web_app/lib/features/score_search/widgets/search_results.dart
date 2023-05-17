import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:score/features/score_search/behaviours/search_page.dart';
import 'package:score/features/score_search/models/score.dart';
import 'package:score/features/score_search/models/search_result.dart';
import 'package:score/features/score_search/widgets/score_list_item.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';
import 'package:score/shared/dependency_management/global_value.dart';

class SearchResults extends StatefulWidget {
  const SearchResults({super.key});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  final pagingController = PagingController<int, Score>(firstPageKey: 0);

  late final SearchResultValue searchResult = context.getIt();
  late final GlobalValueListenable<SearchResult?> searchResultListenable =
      GlobalValueListenable(globalValue: searchResult);
  late final SearchPage searchPage = context.getIt();
  late final StreamSubscription searchResultSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    searchResultSubscription = searchResult.changes
        .where((result) => result != null)
        .cast<SearchResult>()
        .listen(appendPage);

    pagingController.addPageRequestListener(searchPage);
  }

  void appendPage(SearchResult result) {
    if (result.isFirstPage) {
      pagingController.refresh();
    }
    pagingController.appendPage(result.hits, result.nextPage);
  }

  @override
  void dispose() {
    pagingController.dispose();
    searchResultSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, Score>(
      pagingController: pagingController,
      builderDelegate: PagedChildBuilderDelegate(
        itemBuilder: (context, score, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          child: ScoreListItem(score: score),
        ),
      ),
    );
  }
}

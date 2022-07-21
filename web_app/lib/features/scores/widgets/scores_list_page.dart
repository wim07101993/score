import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:score/features/scores/behaviours/search_scores.dart';
import 'package:score/features/scores/change_notifiers/search_string_notifier.dart';
import 'package:score/features/scores/widgets/score_search_result_item.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/shared/models/pagination_page.dart';
import 'package:score/shared/models/score.dart';

class ScoresListPage extends StatefulWidget {
  const ScoresListPage({
    super.key,
  });

  @override
  State<ScoresListPage> createState() => _ScoresListPageState();
}

class _ScoresListPageState extends State<ScoresListPage> {
  late final SearchScores _searchScores;
  late final SearchStringNotifier _searchString;
  final _pagingController = PagingController<int, Score>(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _searchScores = context.read();
    _searchString = context.read();
    _searchString.addListener(_onSearchStringChanged);
    _pagingController.addPageRequestListener(_fetchPage);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _searchString.removeListener(_onSearchStringChanged);
    _pagingController.removePageRequestListener(_fetchPage);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(builder: (context, notifier, child) {
      return PagedListView(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Score>(
          itemBuilder: (context, item, index) {
            return ScoreSearchResultItem(score: item);
          },
        ),
      );
    });
  }

  void _onSearchStringChanged() => _pagingController.refresh();

  void _fetchPage(int pageIndex) {
    if (_searchString.text.isEmpty) {
      _pagingController.appendLastPage(const []);
      return;
    }
    _searchScores(SearchScoresParams(
      searchString: _searchString.text,
      pageIndex: pageIndex,
    )).thenWhen(_onSearchError, _onSearchResult);
  }

  void _onSearchError(Exception e) {}

  void _onSearchResult(PaginationPage<Score> page) {
    if (page.index < page.numberOfPages - 1) {
      _pagingController.appendPage(page.items, page.index + 1);
    } else {
      _pagingController.appendLastPage(page.items);
    }
  }
}

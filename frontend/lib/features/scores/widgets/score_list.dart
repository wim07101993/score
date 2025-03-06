import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:score/shared/api/generated/searcher.pb.dart';

class ScoreList extends StatelessWidget {
  const ScoreList({
    super.key,
    required this.pagingController,
    this.scrollDirection = Axis.horizontal,
  });

  final Axis scrollDirection;
  final PagingController<int, Score> pagingController;

  @override
  Widget build(BuildContext context) {
    return PagingListener(
      controller: pagingController,
      builder: (context, state, fetchNextPage) => PagedListView(
        state: state,
        scrollDirection: scrollDirection,
        fetchNextPage: fetchNextPage,
        builderDelegate: PagedChildBuilderDelegate(
          itemBuilder: (context, item, index) {
            return Text(index.toString());
          },
        ),
      ),
    );
  }
}

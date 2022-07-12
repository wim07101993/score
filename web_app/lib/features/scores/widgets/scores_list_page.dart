import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/shared/data/firebase/firestore/firestore_extensions.dart';
import 'package:score/shared/data/firebase/firestore/query_extensions.dart';
import 'package:score/shared/data/models/score.dart';

class ScoresListPage extends StatefulWidget {
  const ScoresListPage({
    super.key,
  });

  @override
  State<ScoresListPage> createState() => _ScoresListPageState();
}

class _ScoresListPageState extends State<ScoresListPage> {
  static const int _pageSize = 25;

  late final FirebaseFirestore _firestore;
  final _controller = PagingController<int, Score>(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _firestore = Provider.of<FirebaseFirestore>(context, listen: false);
    _controller.addPageRequestListener((pageIndex) async {
      final page = await _firestore
          .scores(pageIndex: pageIndex, pageSize: _pageSize)
          .items;
      if (page.length != _pageSize) {
        _controller.appendLastPage(page);
      } else {
        _controller.appendPage(page, pageIndex + _pageSize);
      }
    });
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(builder: (context, notifier, child) {
      return PagedListView(
        pagingController: _controller,
        builderDelegate: PagedChildBuilderDelegate<Score>(
          itemBuilder: (context, item, index) => Text(item.title),
        ),
      );
    });
  }
}

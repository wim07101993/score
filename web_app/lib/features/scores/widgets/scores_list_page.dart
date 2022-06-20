import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:score/features/scores/data/firestore_extensions.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/shared/data/firebase/firestore_extensions.dart';

class ScoresListPage extends StatefulWidget {
  const ScoresListPage({
    super.key,
  });

  @override
  State<ScoresListPage> createState() => _ScoresListPageState();
}

class _ScoresListPageState extends State<ScoresListPage> {
  static const int _pageSize = 25;

  late final CollectionReference<Map<String, dynamic>> _scoreCollection;
  final _controller = PagingController<int, Score>(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scoreCollection = Provider.of<FirebaseFirestore>(context, listen: false)
          .scoreCollection;
      _controller.addPageRequestListener((pageIndex) async {
        final page =
            (await _scoreCollection.page(pageIndex, _pageSize)).toList();
        if (page.length != _pageSize) {
          _controller.appendLastPage(page);
        } else {
          _controller.appendPage(page, pageIndex + _pageSize);
        }
      });
      if (mounted) {
        // TODO set
        setState(() {});
      }
    });
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

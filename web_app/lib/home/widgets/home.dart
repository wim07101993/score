import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:score/features/scores/change_notifiers/search_string_notifier.dart';
import 'package:score/home/widgets/large_app_bar.dart';

class Home extends StatelessWidget {
  const Home({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => context.read<GetIt>().call<SearchStringNotifier>(),
      child: const Scaffold(
        appBar: LargeAppBar(),
        body: AutoRouter(),
      ),
    );
  }
}

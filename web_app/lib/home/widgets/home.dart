import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:score/features/scores/change_notifiers/search_string_notifier.dart';
import 'package:score/home/widgets/large_app_bar.dart';
import 'package:score/router/app_router.gr.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _router.push(const ScoresListRoute()),
    );
    return Provider(
      create: (_) => context.read<GetIt>().call<SearchStringNotifier>(),
      child: Scaffold(
        appBar: LargeAppBar(router: _router),
        body: Router(
          restorationScopeId: 'router',
          routeInformationParser: _router.defaultRouteParser(
            includePrefixMatches: true,
          ),
          routerDelegate: AutoRouterDelegate(_router),
        ),
      ),
    );
  }
}

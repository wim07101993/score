import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide AppBar;
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
  final _searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _router.push(const ScoresListRoute()),
    );
    return Scaffold(
      appBar: LargeAppBar(
        router: _router,
      ),
      body: Router(
        restorationScopeId: 'router',
        routeInformationParser: _router.defaultRouteParser(
          includePrefixMatches: true,
        ),
        routerDelegate: AutoRouterDelegate(_router),
      ),
    );
  }
}

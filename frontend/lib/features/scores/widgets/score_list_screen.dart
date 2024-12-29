import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/routing/app_router.gr.dart';

@RoutePage()
class ScoreListScreen extends StatelessWidget {
  const ScoreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('SCORES'),
        actions: [
          IconButton(
            onPressed: () => AutoRouter.of(context).push(const UserInfoRoute()),
            icon: const Icon(Icons.account_circle),
          ),
          IconButton(
            onPressed: () => AutoRouter.of(context).push(const LogsRoute()),
            icon: const Icon(Icons.developer_mode),
          ),
        ],
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
      ),
    );
  }
}

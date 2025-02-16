import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/routing/app_router.gr.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Placeholder(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    SizedBox(
                      height: 200,
                      child: Placeholder(),
                    ),
                    SizedBox(
                      height: 200,
                      child: Placeholder(),
                    ),
                    SizedBox(
                      height: 200,
                      child: Placeholder(),
                    ),
                    SizedBox(
                      height: 200,
                      child: Placeholder(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

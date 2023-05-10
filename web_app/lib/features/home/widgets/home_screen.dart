import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/auth/behaviours/logout.dart';
import 'package:score/features/score_search/widgets/search_field.dart';
import 'package:score/features/score_search/widgets/search_results.dart';
import 'package:score/shared/dependency_management/get_it_build_context_extensions.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [_popUpMenuButton(theme)],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Score',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const SearchField(),
              const SizedBox(),
              const SearchResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popUpMenuButton(ThemeData theme) {
    return PopupMenuButton(
      color: theme.primaryColor,
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: context.getIt<Logout>(),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 8),
              const Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }
}

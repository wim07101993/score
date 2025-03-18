import 'package:auto_route/auto_route.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/auth/behaviours/log_in.dart';
import 'package:score/features/auth/user.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/widgets/score_search_bar.dart';
import 'package:score/routing/app_router.gr.dart';
import 'package:score/shared/widgets/exceptions.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _syncScores() async {
    final userManager = await GetIt.I.getAsync<OidcUserManager>();
    if (!mounted) {
      return;
    }
    final currentUser = userManager.currentUser;
    if (currentUser == null || currentUser.isSessionExpired) {
      final login = await GetIt.I.getAsync<LogIn>();
      final loginResult = await login();
      if (!mounted) {
        return;
      }
      // After logging in the score-syncer automatically syncs scores. No need
      // to trigger that behaviour here as well.
      return loginResult.when(
        (exception) => showUnknownErrorDialog(context),
        (_) {},
      );
    }

    if (!mounted) {
      return;
    }
    final syncScores = await GetIt.I.getAsync<SyncScores>();
    final result = await syncScores(currentUser);
    if (!mounted) {
      return;
    }
    result.when(
      (exception) => showUnknownErrorDialog(context),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 96,
        title: const ScoreSearchBar(),
        actions: [
          IconButton(
            onPressed: _syncScores,
            icon: const Icon(Icons.sync),
          ),
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
      body: const AutoRouter(),
    );
  }
}

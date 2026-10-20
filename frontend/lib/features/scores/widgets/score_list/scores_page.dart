import 'package:auto_route/auto_route.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/features/auth/widgets/sign_in_button.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/notifiers/is_syncing_scores_notifier.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/widgets/score_list/score_library.dart';
import 'package:score/features/scores/widgets/upload_score_fab.dart';
import 'package:score/router.dart';
import 'package:score/widgets/collections_button.dart';
import 'package:score/widgets/exceptions.dart';
import 'package:score/widgets/profile_button.dart';
import 'package:score/widgets/sets_button.dart';
import 'package:score/widgets/settings_button.dart';
import 'package:score/widgets/sync_button.dart';

@RoutePage()
class const ScoresPage({
  super.key,
}) extends StatefulWidget {
  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  final _auth = GetIt.I<AuthNotifier>();
  final _scores = GetIt.I<ScoresNotifier>();

  Future<void> sync() async {
    final result = await GetIt.I<SyncScores>()();
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success():
        return;
      case Failed(reason: final exception):
        // TODO proper error messages
        await showExceptionDialog(
          context,
          title: 'Failed to sync scores',
          message: exception.toString(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _auth,
      builder: (context, user, _) => _page(context, user),
    );
  }

  Widget _page(BuildContext context, UserInfo? user) {
    final mayView = user?.isScoreViewer == true;
    final mayEdit = user?.isScoreEditor == true;

    return Scaffold(
      appBar: _appBar(context, mayView),
      floatingActionButton: mayEdit ? const UploadScoreFab() : null,
      body: !mayView
          ? _NotAViewer(signedIn: _auth.value != null)
          : Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: GetIt.I<IsSyncingScoresNotifier>(),
                  builder: (context, isSyncing, _) => isSyncing
                      ? const LinearProgressIndicator()
                      : const SizedBox(),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _scores,
                    builder: (context, _) => ScoreLibrary(
                      scores: _scores.scores,
                      onScoreTapped: (score) {
                        context.router.push(
                          ScoreDetailRoute(scoreId: score.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  AppBar _appBar(BuildContext context, bool canViewScores) {
    return AppBar(
      title: const Text('Scores'),
      actions: [
        if (canViewScores) const SetsButton(),
        if (canViewScores) const CollectionsButton(),
        if (canViewScores) const SyncButton(),
        const SettingsButton(),
        const ProfileButton(),
      ],
    );
  }
}

class const _NotAViewer({
  required final bool signedIn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(signedIn ? Icons.lock_outline : Icons.login, size: 40),
            const SizedBox(height: 12),
            Text(
              signedIn
                  ? 'This account has not been given the role that reads'
                        ' scores.'
                  : 'Sign in to read the scores.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (signedIn)
              FilledButton.tonal(
                onPressed: () => context.router.push(const ProfileRoute()),
                child: const Text('See what the provider said'),
              )
            else
              const SignInButton(),
          ],
        ),
      ),
    );
  }
}

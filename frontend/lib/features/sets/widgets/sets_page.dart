import 'package:auto_route/auto_route.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/sets/behaviours/sync_sets.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sync/behaviours/syncer.dart';
import 'package:score/router.dart';
import 'package:score/widgets/offline_notice.dart';
import 'package:score/widgets/sync_button.dart';

/// The sets there are.
///
/// A set is a playlist for a gig: the scores that are played, in playing order,
/// each in the key it is played in.
@RoutePage()
class const SetsPage({
  super.key,
}) extends StatefulWidget {
  @override
  State<SetsPage> createState() => _SetsPageState();
}

class _SetsPageState extends State<SetsPage> {
  final _auth = GetIt.I<AuthNotifier>();
  final _sets = GetIt.I<SetsNotifier>();

  bool _offline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    if (_auth.value?.isScoreViewer != true) return;

    final synced = await GetIt.I<SyncSets>()();
    // The scores are what a set is built out of, so a set that was written on
    // another device is only readable here once its scores are.
    await GetIt.I<SyncScores>()();

    if (mounted) {
      setState(
        () => _offline =
            synced is Failed<void> &&
            synced.reason is NoConnectionSyncerException,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Who is signed in decides what the page shows.
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) => _page(context),
    );
  }

  Widget _page(BuildContext context) {
    final mayView = _auth.value?.isScoreViewer == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sets'),
        actions: [if (mayView) const SyncButton()],
      ),
      floatingActionButton: mayView
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.router.push(SetDetailRoute(setId: 'new')),
              icon: const Icon(Icons.add),
              label: const Text('New set'),
            )
          : null,
      body: !mayView
          ? const Center(child: Text('Sets are for score viewers.'))
          : ListenableBuilder(
              listenable: _sets,
              builder: (context, _) {
                final sets = _sets.sets;

                return RefreshIndicator(
                  onRefresh: _sync,
                  child: sets.isEmpty
                      ? ListView(
                          children: [
                            // A device that has never reached the server has
                            // no sets because it has not been told of any, not
                            // because there are none.
                            if (_offline) const OfflineNotice(),
                            const SizedBox(height: 80),
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No sets yet. A set is a playlist for a gig:'
                                ' the scores that are played, in playing order,'
                                ' each in the key it is played in.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: sets.length + (_offline ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_offline && index == 0) {
                              return const OfflineNotice();
                            }
                            final set = sets[index - (_offline ? 1 : 0)];
                            return _SetCard(set: set);
                          },
                        ),
                );
              },
            ),
    );
  }
}

class const _SetCard({
  required final ScoreSet set,
}) extends StatelessWidget {
  /// What is worth saying about a set beyond what it holds: whose it is, and
  /// whether the server has heard about it yet.
  ///
  /// A set that is still owed to the server is playable all the same, which is
  /// the point, but saying so is what keeps "I edited that" and "the others can
  /// see it" apart.
  String get _state {
    if (!set.isOwner) return 'shared with you';
    if (set.sharedWith.isNotEmpty) {
      return 'shared with ${set.sharedWith.length}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = set.entries.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.router.push(SetDetailRoute(setId: set.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(set.displayTitle, style: theme.textTheme.titleMedium),
              if (set.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(set.description, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$count score${count == 1 ? '' : 's'}',
                    style: theme.textTheme.labelMedium,
                  ),
                  if (_state.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_state),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

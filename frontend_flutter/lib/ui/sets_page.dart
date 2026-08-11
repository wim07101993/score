import 'package:flutter/material.dart';

import '../app.dart';
import '../domains/sets/models.dart';
import 'routes.dart';

/// The sets there are.
///
/// A set is a playlist for a gig: the scores that are played, in playing order,
/// each in the key it is played in.
class SetsPage extends StatefulWidget {
  const SetsPage({super.key});

  @override
  State<SetsPage> createState() => _SetsPageState();
}

class _SetsPageState extends State<SetsPage> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final app = AppScope.read(context);
    if (app.user?.isScoreViewer != true) return;

    await app.updateSets();
    // The scores are what a set is built out of, so a set that was written on
    // another device is only readable here once its scores are.
    await app.updateScores();

    final reachable = await app.setsApi.canBeReached();
    if (mounted) {
      setState(() => _offline = !reachable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mayView = app.user?.isScoreViewer == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Sets')),
      floatingActionButton: mayView
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoute.newSet()),
              icon: const Icon(Icons.add),
              label: const Text('New set'),
            )
          : null,
      body: !mayView
          ? const Center(child: Text('Sets are for score viewers.'))
          : ListenableBuilder(
              listenable: app.sets,
              builder: (context, _) {
                final sets = app.sets.sets;

                return RefreshIndicator(
                  onRefresh: _sync,
                  child: sets.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Padding(
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
                              return const _OfflineNotice();
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

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'The server cannot be reached. What is here is what this device'
          ' knows; edits are kept and sent as soon as it can be reached again.',
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.set});

  final ScoreSet set;

  /// What is worth saying about a set beyond what it holds: whose it is, and
  /// whether the server has heard about it yet.
  ///
  /// A set that is still owed to the server is playable all the same, which is
  /// the point, but saying so is what keeps "I edited that" and "the others can
  /// see it" apart.
  String get _state {
    if (!set.isOwner) return 'shared with you';
    if (set.owesAnything) return 'not sent yet';
    if (set.sharedWith.isNotEmpty) return 'shared with ${set.sharedWith.length}';
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
        onTap: () => Navigator.of(context).pushNamed(AppRoute.set(set.id)),
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
                  Text('$count score${count == 1 ? '' : 's'}',
                      style: theme.textTheme.labelMedium),
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

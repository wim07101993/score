import 'package:flutter/material.dart';

import '../app.dart';
import '../data/instruments.dart';
import '../domains/scores/models.dart';
import 'routes.dart';

/// The scores there are.
///
/// What is on screen is what this device has, whether or not there is anything
/// to sync with; syncing only ever adds to it. The most recently opened come
/// first, because what was played last is what is likely to be played next.
class ScoresPage extends StatefulWidget {
  const ScoresPage({super.key});

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  String _filter = '';
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final app = AppScope.read(context);
    if (app.user?.isScoreViewer != true) {
      return;
    }

    setState(() => _syncing = true);
    await app.updateScores();
    // Whatever was written to a set while there was nothing to send it to is
    // still owed to the server, and any page with a network is a chance to send
    // it: waiting for the player to open the sets again is waiting for nothing.
    await app.updateSets();
    if (mounted) {
      setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mayView = app.user?.isScoreViewer == true;
    final mayEdit = app.user?.isScoreEditor == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scores'),
        actions: [
          if (mayView)
            IconButton(
              tooltip: 'Sets',
              icon: const Icon(Icons.queue_music),
              onPressed: () => Navigator.of(context).pushNamed('/sets'),
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          // Never hidden, whatever roles the user turns out to have: a user who
          // is shown nothing at all is exactly the user who needs to see why.
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
      floatingActionButton: mayEdit
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoute.newScore()),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
      body: !mayView
          ? _NotAViewer(problem: app.authProblem)
          : ListenableBuilder(
              listenable: app.scores,
              builder: (context, _) {
                final needle = _filter.trim().toLowerCase();
                final scores = app.scores.scores
                    .where((score) =>
                        needle.isEmpty || score.searchText.contains(needle))
                    .toList();

                return RefreshIndicator(
                  onRefresh: _sync,
                  child: Column(
                    children: [
                      if (_syncing) const LinearProgressIndicator(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'title, creator or tag',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() => _filter = value),
                        ),
                      ),
                      Expanded(
                        child: scores.isEmpty
                            ? _Empty(filtered: needle.isNotEmpty)
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: scores.length,
                                itemBuilder: (context, index) =>
                                    ScoreCard(score: scores[index]),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// One score in the list: what it is called, who wrote it, what plays it.
class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.score, this.onTap});

  final Score score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creators = score.creatorNames.join(', ');
    final playedBy =
        score.instruments.map(instrumentName).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ??
            () => Navigator.of(context).pushNamed(AppRoute.score(score.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(score.title, style: theme.textTheme.titleMedium),
              if (creators.isNotEmpty) ...[
                const SizedBox(height: 6),
                _Line(icon: Icons.person_outline, text: creators),
              ],
              if (playedBy.isNotEmpty) ...[
                const SizedBox(height: 4),
                _Line(icon: Icons.piano_outlined, text: playedBy),
              ],
              if (score.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in score.tags)
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Text(
            filtered
                ? 'No score here matches that.'
                : 'No scores on this device yet.\nThey arrive with the next sync.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// What a user who may not read scores is shown.
///
/// Not an empty list: an empty list says there is nothing, and that is not what
/// happened. A page that shows nothing is a page that was told nothing, and the
/// profile is where what it was told can be read.
class _NotAViewer extends StatelessWidget {
  const _NotAViewer({this.problem});

  /// What went wrong signing in, when something did. A sign-in that failed
  /// looks exactly like an account with no roles, and the two want opposite
  /// things done about them.
  final Object? problem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = problem != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(failed ? Icons.error_outline : Icons.lock_outline, size: 40),
            const SizedBox(height: 12),
            Text(
              failed
                  ? 'Signing in did not finish.'
                  : 'This account has not been given the role that reads'
                      ' scores.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (failed) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  '$problem',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pushNamed('/profile'),
              child: const Text('See what the provider said'),
            ),
          ],
        ),
      ),
    );
  }
}

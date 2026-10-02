import 'package:flutter/material.dart';
import 'package:score/app.dart';
import 'package:score/features/scores/instruments.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/widgets/add_to_list_button.dart';
import 'package:score/features/scores/widgets/score_library.dart';
import 'package:score/features/scores/widgets/upload_score_fab.dart';
import 'package:score/routes.dart';
import 'package:score/widgets/collections_button.dart';
import 'package:score/widgets/profile_button.dart';
import 'package:score/widgets/sets_button.dart';
import 'package:score/widgets/settings_button.dart';
import 'package:score/widgets/sync_button.dart';

/// The scores there are.
///
/// What is on screen is what this device has, whether or not there is anything
/// to sync with; syncing only ever adds to it. The most recently opened come
/// first, because what was played last is what is likely to be played next.
class ScoresPage extends StatefulWidget {
  const ScoresPage({
    super.key,
  });

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
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
    // Whatever was written to a set or a collection while there was nothing to
    // send it to is still owed to the server, and any page with a network is a
    // chance to send it: waiting for the player to open the sets or the
    // collections again is waiting for nothing.
    await app.updateSets();
    await app.updateCollections();
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
          if (mayView) const SetsButton(),
          // A collection names scores but changes nothing about them, so
          // keeping one asks no more of a player than reading the scores in it.
          if (mayView) const CollectionsButton(),
          if (mayView) const SyncButton(),
          const SettingsButton(),
          const ProfileButton(),
        ],
      ),
      floatingActionButton: mayEdit ? const UploadScoreFab() : null,
      body: !mayView
          ? _NotAViewer(problem: app.authProblem)
          : Column(
              children: [
                if (_syncing) const LinearProgressIndicator(),
                Expanded(
                  child: ListenableBuilder(
                    listenable: app.scores,
                    builder: (context, _) => ScoreLibrary<Score>(
                      items: app.scores.scores,
                      scoreOf: (score) => score,
                      itemBuilder: (context, score) => ScoreCard(score: score),
                      empty: 'No scores on this device yet.\nThey arrive with'
                          ' the next sync.',
                      onRefresh: _sync,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One score in the list: what it is called, who wrote it, what plays it.
///
/// The same card wherever a list of scores is shown — the list of every score,
/// and the pieces of a collection — so that a piece looks the same in the book
/// as it does on the shelf.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.score,
    this.onTap,
    this.note,
  });

  final Score score;

  /// What a tap does, when it is not opening the score on its own: a piece of
  /// a collection opens as that piece, read the way the collection says.
  final VoidCallback? onTap;

  /// What the list it is in says next to it, if anything.
  final String? note;

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
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          // The buttons that put the score into a set or a collection are
          // beside all of it, in the middle, rather than beside the title.
          child: Row(
            children: [
              Expanded(
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
                    if ((note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _Line(icon: Icons.sticky_note_2_outlined, text: note!),
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
              AddToListButtons(scoreId: score.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
  });

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

/// What a user who may not read scores is shown.
///
/// Not an empty list: an empty list says there is nothing, and that is not what
/// happened. A page that shows nothing is a page that was told nothing, and the
/// profile is where what it was told can be read.
class _NotAViewer extends StatelessWidget {
  const _NotAViewer({
    this.problem,
  });

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

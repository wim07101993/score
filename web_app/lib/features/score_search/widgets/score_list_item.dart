import 'package:flutter/material.dart';
import 'package:score/features/score_search/models/part.dart';
import 'package:score/features/score_search/models/score.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ScoreListItem extends StatelessWidget {
  const ScoreListItem({
    super.key,
    required this.score,
  });

  final Score score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final alsoKnownAs = score.alsoKnownAs.toList(growable: false)
      ..sort((a, b) => a.compareTo(b));
    final creators = score.creators.toList(growable: false)
      ..sort((a, b) => a.compareTo(b));
    final instruments = score.instruments.toList(growable: false)
      ..sort((a, b) => a.compareTo(b));

    final allLinksAreTheSame =
        score.parts.expand((part) => part.files).toSet().length == 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    score.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.primaryColor),
                  ),
                ),
                if (allLinksAreTheSame)
                  IconButton(
                    onPressed: () => launchUrlString(
                      (score.parts.first.files.first as LinkedFile).link,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                  ),
              ],
            ),
            const Divider(),
            if (score.arrangementName?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text('(TODO arrangement: ${score.arrangementName})'),
            ],
            if (alsoKnownAs.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('AKA: ${alsoKnownAs.join(", ")}'),
            ],
            if (creators.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('TODO Creators: ${creators.join(", ")}'),
            ],
            if (instruments.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('TODO instruments: ${instruments.join(", ")}'),
            ],
          ],
        ),
      ),
    );
  }
}

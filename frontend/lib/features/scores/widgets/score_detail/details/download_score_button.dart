import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/scores/behaviours/download_score.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/widgets/score_detail/details/score_about.dart';
import 'package:score/widgets/exceptions.dart';
import 'package:songbird_score/songbird_score.dart' as mxml;

class const DownloadScoreButton({
  super.key,
  required final mxml.Score scoreData,
  required final Score scoreProperties,
  required final ScoreViewController viewController,
}) extends StatelessWidget {
  Future<void> download(
    BuildContext context,
    ScoreViewSettings viewSettings,
  ) async {
    final result = await GetIt.I<DownloadScore>()(
      DownloadScoreParams(
        scoreData: scoreData,
        score: scoreProperties,
        view: viewSettings,
      ),
    );
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case Success():
        return;
      case Failed<void>(reason: final exception):
        await showExceptionDialog(
          context,
          title: 'failed to download score',
          message: exception.toString(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, menu, _) => OutlinedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text('Download'),
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
      menuChildren: [
        DownloadButtonMenuItem(
          onPressed: () {
            download(context, const ScoreViewSettings.defaultView());
          },
          icon: Icons.description_outlined,
          title: 'Score file, as written (.musicxml)',
          subtitle:
              'The score itself, as it was uploaded. It opens in other'
              ' music software and can be uploaded here again.',
        ),
        DownloadButtonMenuItem(
          onPressed: () {
            download(context, viewController.scoreViewSettings);
          },
          icon: Icons.visibility_outlined,
          title: 'Score file, as on screen (.musicxml)',
          subtitle:
              'In the key you are reading it in, without the parts you'
              ' have hidden. Not the original: do not upload it over this'
              ' score.',
        ),
      ],
    );
  }
}

class const DownloadButtonMenuItem({
  required final IconData icon,
  required final String title,
  required final String subtitle,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onPressed,
      leadingIcon: Icon(icon),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

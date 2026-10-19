import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/scores/behaviours/download_score.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';
import 'package:score/widgets/exceptions.dart';

class const DownloadScoreButton({
  super.key,
  required final Score score,
  required final String musicXml,
  required final ScoreViewController controller,
}) extends StatelessWidget {
  Future<void> download(
    BuildContext context, {
    required String musicXml,
  }) async {
    final result = await GetIt.I<DownloadScore>()(
      DownloadScoreParams(
        musicXml: musicXml,
        scoreId: score.id,
        title: score.title,
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
          onPressed: () => download(context, musicXml: musicXml),
          icon: Icons.description_outlined,
          title: 'Score file, as written (.musicxml)',
          subtitle:
              'The score itself, as it was uploaded. It opens in other'
              ' music software and can be uploaded here again.',
        ),
        DownloadButtonMenuItem(
          onPressed: () {
            download(context, musicXml: controller.visibleMusicXml);
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

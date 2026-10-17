import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';

class const ScoreDetailSheet({
  super.key,
  required final ScoreReader reader,
  final bool isPaper = false,
  final String paperNote = 'This song is no longer in there.',
  final VoidCallback? onTouched,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (reader.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final failure = reader.failure;
    if (failure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('$failure', textAlign: TextAlign.center),
        ),
      );
    }
    final musicXml = reader.musicXml;
    if (isPaper) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            paperNote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }
    if (musicXml == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'There is nothing to show.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // The page is lit the way this device has been told to light it, and it
    // keeps up with the slider while it is being dragged. What is passed is a
    // whole palette rather than a colour or two: ink and paper only look right
    // if whoever decides one decides the other.
    final settings = GetIt.I<SettingsNotifier>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final look = settings.pageLook(Theme.of(context).brightness);
        return ScoreSheet(
          musicXml: musicXml,
          view: reader.view,
          space: reader.space,
          onPinched: (pinched) {
            reader.pinch(pinched);
            onTouched?.call();
          },
          palette: SheetPalette.lamp(
            brightness: look.brightness,
            warmth: look.warmth,
          ),
        );
      },
    );
  }
}

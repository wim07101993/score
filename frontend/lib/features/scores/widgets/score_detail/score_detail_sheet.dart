import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/notation/widgets/score_sheet.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:score/features/settings/notifiers/settings_notifier.dart';

class const ScoreDetailSheet({
  super.key,
  required final ScoreReader reader,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (reader.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final failure = reader.failure;
    if (failure != null) {
      return _Message('$failure');
    }
    final view = reader.view;
    if (view == null) {
      return const _Message('There is nothing to show.');
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
          controller: view.scoreController,
          palette: SheetPalette.lamp(
            brightness: look.brightness,
            warmth: look.warmth,
          ),
        );
      },
    );
  }
}

class const _Message(
  final String text,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

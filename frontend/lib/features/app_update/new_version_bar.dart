import 'package:flutter/material.dart';
import 'package:score/features/app_update/app_update.dart';

/// Puts a bar under [child] once a new version of the app is ready, offering to
/// start again on it.
///
/// Offered rather than done: the app is on a stage, and starting again in the
/// middle of a song — or of a note being typed — is not for the app to decide.
class NewVersionBar extends StatelessWidget {
  const NewVersionBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: newVersionReady,
      builder: (context, ready, child) => Column(
        children: [
          Expanded(child: child!),
          if (ready)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('A new version of the app is ready.'),
                      ),
                      TextButton(
                        onPressed: startOnTheNewVersion,
                        child: Text('Reload'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}

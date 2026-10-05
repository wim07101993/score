import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/router.dart';

/// The way to the settings.
class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.router.push(const SettingsRoute()),
    );
  }
}

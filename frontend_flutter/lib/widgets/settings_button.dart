import 'package:flutter/material.dart';

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
      onPressed: () => Navigator.of(context).pushNamed('/settings'),
    );
  }
}

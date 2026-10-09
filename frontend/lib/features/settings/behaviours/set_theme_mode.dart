import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:score/features/settings/models.dart';
import 'package:score/features/settings/storage/settings_store.dart';
import 'package:score/features/settings/storage/theme_hint.dart';

/// Makes the app light, dark, or whatever the machine says, from now on.
class SetThemeMode({
  super.monitor,
  required final SettingsStore store,
}) extends Behaviour<ThemeMode, void> {
  @override
  String get description => 'setting the theme';

  @override
  Future<void> action(ThemeMode input, BehaviourTrack? track) async {
    track?.addAttribute('mode', input.name);
    // Where the page reads it before the app has loaded: see
    // [rememberedThemeMode].
    rememberThemeMode(input);
    await store.write(
      themeModeKey,
      themeModeToStore(input),
    );
  }
}
